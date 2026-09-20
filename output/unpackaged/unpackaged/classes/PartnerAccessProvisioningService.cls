/**
 * Governed v2 relationship and access-request boundary around technical
 * provisioning.
 */
public without sharing class PartnerAccessProvisioningService {
  @TestVisible
  private static Boolean testAccessManagementAuthority = false;

  /**
   * Result of checking whether a partner relationship is ready for
   * enablement, including which prerequisites (if any) are still
   * outstanding.
   */
  public class EnablementDiagnostic {
    /**
     * Whether an effective agreement exists for the relationship's
     * onboarding.
     */
    @AuraEnabled
    public Boolean agreementsEffective;
    /**
     * Whether the relationship's Account is enabled as a Salesforce
     * partner.
     */
    @AuraEnabled
    public Boolean accountIsPartner;
    /**
     * Whether the given contact belongs to the relationship's Account.
     */
    @AuraEnabled
    public Boolean contactEligible;
    /**
     * Whether all enablement prerequisites are satisfied.
     */
    @AuraEnabled
    public Boolean ready;
    /**
     * Human-readable descriptions of any unmet enablement prerequisites.
     */
    @AuraEnabled
    public List<String> blockers = new List<String>();
  }

  /**
   * Creates or updates the Partner_Relationship__c for an onboarding once
   * an effective agreement exists, and links it back to the onboarding
   * record.
   *
   * @param onboardingId Id of the Partner_Onboarding__c the relationship
   * belongs to.
   * @param accountId Id of the Account the relationship is with.
   * @param programmeKey Key identifying the partner programme.
   * @param awardedTier Tier awarded as part of the relationship.
   * @param relationshipKey Idempotency key used to upsert the relationship.
   * @return The created or updated Partner_Relationship__c record.
   */
  public static Partner_Relationship__c establishRelationship(
    Id onboardingId,
    Id accountId,
    String programmeKey,
    String awardedTier,
    String relationshipKey
  ) {
    assertAccessManagementAuthority();
    Integer effectiveAgreements = [
      SELECT COUNT()
      FROM Partner_Agreement__c
      WHERE Onboarding__c = :onboardingId AND Status__c = 'Effective'
      WITH SYSTEM_MODE
    ];
    if (effectiveAgreements == 0) {
      throw new PartnerAccessException(
        'An effective agreement is required before relationship establishment.'
      );
    }
    Partner_Relationship__c relationship = new Partner_Relationship__c(
      Onboarding__c = onboardingId,
      Account__c = accountId,
      Programme_Key__c = programmeKey,
      Awarded_Tier__c = awardedTier,
      Relationship_Key__c = relationshipKey,
      Status__c = 'Pending Enablement',
      Effective_On__c = Date.today()
    );
    Database.upsert(
      relationship,
      Partner_Relationship__c.Fields.Relationship_Key__c,
      AccessLevel.SYSTEM_MODE
    );
    Database.update(
      new Partner_Onboarding__c(
        Id = onboardingId,
        Partner_Account__c = accountId
      ),
      AccessLevel.SYSTEM_MODE
    );
    return relationship;
  }

  /**
   * Evaluates whether a partner relationship meets all enablement
   * prerequisites, and activates it if it now does.
   *
   * @param relationshipId Id of the Partner_Relationship__c to evaluate.
   * @param contactId Id of the Contact to check eligibility for.
   * @return An EnablementDiagnostic describing readiness and any
   * blockers.
   */
  public static EnablementDiagnostic evaluateEnablement(
    Id relationshipId,
    Id contactId
  ) {
    assertAccessManagementAuthority();
    Partner_Relationship__c relationship = [
      SELECT Id, Onboarding__c, Account__c, Account__r.IsPartner, Status__c
      FROM Partner_Relationship__c
      WHERE Id = :relationshipId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];
    EnablementDiagnostic result = new EnablementDiagnostic();
    result.agreementsEffective =
      [
        SELECT COUNT()
        FROM Partner_Agreement__c
        WHERE
          Onboarding__c = :relationship.Onboarding__c
          AND Status__c = 'Effective'
        WITH SYSTEM_MODE
      ] > 0;
    result.accountIsPartner = relationship.Account__r.IsPartner;
    result.contactEligible =
      [
        SELECT COUNT()
        FROM Contact
        WHERE Id = :contactId AND AccountId = :relationship.Account__c
        WITH SYSTEM_MODE
      ] == 1;
    if (!result.agreementsEffective)
      result.blockers.add('Required agreement is not effective.');
    if (!result.accountIsPartner)
      result.blockers.add('Account is not enabled as a Salesforce partner.');
    if (!result.contactEligible)
      result.blockers.add(
        'Contact is not associated with the partner Account.'
      );
    result.ready = result.blockers.isEmpty();
    if (result.ready && relationship.Status__c == 'Pending Enablement') {
      relationship.Status__c = 'Active';
      Database.update(relationship, AccessLevel.SYSTEM_MODE);
    }
    return result;
  }

  /**
   * Creates an access request for a contact against an active partner
   * relationship.
   *
   * @param onboardingId Id of the Partner_Onboarding__c the request
   * belongs to.
   * @param relationshipId Id of the active Partner_Relationship__c the
   * request is made against.
   * @param contactId Id of the Contact the access is requested for.
   * @param accessBundle Name of the access bundle being requested.
   * @param requestKey Idempotency key used to upsert the request.
   * @param expiresOn Date the requested access should expire, if any.
   * @return The created or updated Partner_Access_Request__c record.
   */
  public static Partner_Access_Request__c requestAccess(
    Id onboardingId,
    Id relationshipId,
    Id contactId,
    String accessBundle,
    String requestKey,
    Date expiresOn
  ) {
    assertAccessManagementAuthority();
    Partner_Relationship__c relationship = [
      SELECT Id, Onboarding__c, Status__c
      FROM Partner_Relationship__c
      WHERE Id = :relationshipId
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    if (
      relationship.Onboarding__c != onboardingId ||
      relationship.Status__c != 'Active'
    ) {
      throw new PartnerAccessException(
        'An active relationship is required before requesting access.'
      );
    }
    Partner_Access_Request__c request = new Partner_Access_Request__c(
      Onboarding__c = onboardingId,
      Relationship__c = relationshipId,
      Contact__c = contactId,
      Access_Bundle__c = accessBundle,
      Request_Key__c = requestKey,
      Status__c = 'Pending Approval',
      Expires_On__c = expiresOn
    );
    Database.upsert(
      request,
      Partner_Access_Request__c.Fields.Request_Key__c,
      AccessLevel.SYSTEM_MODE
    );
    return request;
  }

  /**
   * Approves a pending, unexpired access request. Requires the
   * PartnerSync_Approve_Partner_Access custom permission.
   *
   * @param requestId Id of the Partner_Access_Request__c to approve.
   * @return The approved Partner_Access_Request__c record.
   */
  public static Partner_Access_Request__c approveAccess(Id requestId) {
    if (
      !FeatureManagement.checkPermission('PartnerSync_Approve_Partner_Access')
    ) {
      throw new PartnerAccessException(
        'Partner access approval authority is required.'
      );
    }
    Partner_Access_Request__c request = [
      SELECT Id, Status__c, Expires_On__c
      FROM Partner_Access_Request__c
      WHERE Id = :requestId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];
    if (
      request.Status__c != 'Pending Approval' ||
      (request.Expires_On__c != null &&
      request.Expires_On__c < Date.today())
    ) {
      throw new PartnerAccessException(
        'Only a current pending request can be approved.'
      );
    }
    request.Status__c = 'Approved';
    request.Approved_By__c = UserInfo.getUserId();
    request.Approved_On__c = System.now();
    Database.update(request, AccessLevel.SYSTEM_MODE);
    return request;
  }

  /**
   * Queues asynchronous provisioning of an approved access request.
   * Requires the PartnerSync_Provision_Partner_Access custom permission.
   *
   * @param requestId Id of the approved Partner_Access_Request__c to
   * provision.
   * @param attemptKey Idempotency key used to upsert the provisioning
   * attempt.
   * @return The queued Partner_Provisioning_Attempt__c record.
   */
  public static Partner_Provisioning_Attempt__c provisionApprovedAccess(
    Id requestId,
    String attemptKey
  ) {
    if (
      !FeatureManagement.checkPermission('PartnerSync_Provision_Partner_Access')
    ) {
      throw new PartnerAccessException(
        'Partner access provisioning authority is required.'
      );
    }
    Partner_Access_Request__c request = [
      SELECT
        Id,
        Contact__c,
        Relationship__r.Account__r.IsPartner,
        Status__c,
        Expires_On__c
      FROM Partner_Access_Request__c
      WHERE Id = :requestId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];
    if (
      request.Status__c != 'Approved' ||
      (request.Expires_On__c != null &&
      request.Expires_On__c < Date.today())
    ) {
      throw new PartnerAccessException(
        'Only an approved, unexpired access request can be provisioned.'
      );
    }
    if (!request.Relationship__r.Account__r.IsPartner) {
      throw new PartnerAccessException(
        'Enable the Account as a Salesforce partner before provisioning access.'
      );
    }
    Partner_Provisioning_Attempt__c attempt = new Partner_Provisioning_Attempt__c(
      Access_Request__c = request.Id,
      Attempt_Key__c = attemptKey,
      Status__c = 'Started',
      Started_On__c = System.now()
    );
    Database.upsert(
      attempt,
      Partner_Provisioning_Attempt__c.Fields.Attempt_Key__c,
      AccessLevel.SYSTEM_MODE
    );
    Id jobId = System.enqueueJob(
      new PartnerAccessProvisioningQueueable(
        request.Id,
        request.Contact__c,
        attempt.Id
      )
    );
    attempt.Status__c = 'Queued';
    attempt.Outcome__c = 'ProvisioningPending:' + String.valueOf(jobId);
    Database.update(attempt, AccessLevel.SYSTEM_MODE);
    request.Status__c = 'Provisioning';
    Database.update(request, AccessLevel.SYSTEM_MODE);
    return attempt;
  }

  /**
   * Thrown when a partner access provisioning operation is attempted
   * without the required authority or against a record in an invalid
   * state.
   */
  public class PartnerAccessException extends Exception {
  }

  private static void assertAccessManagementAuthority() {
    if (
      !FeatureManagement.checkPermission('PartnerSync_Manage_Partner_Access') &&
      !(Test.isRunningTest() && testAccessManagementAuthority)
    ) {
      throw new PartnerAccessException(
        'Partner access management authority is required.'
      );
    }
  }
}
