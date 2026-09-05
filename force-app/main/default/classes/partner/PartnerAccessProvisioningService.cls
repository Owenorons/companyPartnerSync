/** Governed v2 relationship and access-request boundary around technical provisioning. */
public without sharing class PartnerAccessProvisioningService {
  @TestVisible
  private static Boolean testAccessManagementAuthority = false;

  public class EnablementDiagnostic {
    @AuraEnabled
    public Boolean agreementsEffective;
    @AuraEnabled
    public Boolean accountIsPartner;
    @AuraEnabled
    public Boolean contactEligible;
    @AuraEnabled
    public Boolean ready;
    @AuraEnabled
    public List<String> blockers = new List<String>();
  }

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
