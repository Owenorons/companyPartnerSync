/**
 * Identity and feature-level authorization for the current user: resolving
 * which partner account/contact they represent, whether they're internal
 * vs. external, and the canX() capability checks other services build on.
 * Distinct from PartnerRecordAccessService, which answers "can this user see
 * this specific record" rather than "can this user use this feature at all."
 */
public with sharing class PartnerAccessService {
  @TestVisible
  private static Boolean internalUserOverride;
  @TestVisible
  private static Id partnerAccountIdOverride;
  @TestVisible
  private static Contact partnerContactOverride;
  @TestVisible
  private static Map<Id, Id> testPartnerAccountIdsByUser = new Map<Id, Id>();
  @TestVisible
  private static Map<Id, Contact> testPartnerContactsByUser = new Map<Id, Contact>();

  /**
   * Resolves the partner Account Id associated with the running user's
   * contact.
   *
   * @return Id of the partner Account the current user belongs to.
   */
  public static Id getCurrentPartnerAccountId() {
    if (
      Test.isRunningTest() &&
      testPartnerAccountIdsByUser.containsKey(UserInfo.getUserId())
    )
      return testPartnerAccountIdsByUser.get(UserInfo.getUserId());
    if (partnerAccountIdOverride != null)
      return partnerAccountIdOverride;
    User currentUser = [
      SELECT Id, UserType, ContactId, Contact.AccountId
      FROM User
      WHERE Id = :UserInfo.getUserId()
      WITH USER_MODE
      LIMIT 1
    ];

    if (
      currentUser.ContactId == null ||
      currentUser.Contact.AccountId == null
    ) {
      throw new PartnerSyncHandledException(
        'The current user is not linked to a partner account.'
      );
    }

    return currentUser.Contact.AccountId;
  }

  /**
   * Resolves the Contact record associated with the running user.
   *
   * @return The current user's partner Contact record.
   */
  public static Contact getCurrentPartnerContact() {
    if (
      Test.isRunningTest() &&
      testPartnerContactsByUser.containsKey(UserInfo.getUserId())
    )
      return testPartnerContactsByUser.get(UserInfo.getUserId());
    if (partnerContactOverride != null)
      return partnerContactOverride;
    User currentUser = [
      SELECT Id, ContactId
      FROM User
      WHERE Id = :UserInfo.getUserId()
      WITH USER_MODE
      LIMIT 1
    ];

    // if (currentUser.ContactId == null) {
    //   throw new PartnerSyncHandledException(
    //     'The current user is not linked to a partner contact.'
    //   );
    // }

    List<Contact> contacts = [
      SELECT Id, AccountId, Name, Email, Phone, Can_Submit_Deals__c
      FROM Contact
      WHERE Id = :currentUser.ContactId
      WITH USER_MODE
      LIMIT 1
    ];

    // if (contacts.isEmpty()) {
    //   throw new PartnerSyncHandledException(
    //     'The current partner contact could not be found.'
    //   );
    // }

    if (contacts.isEmpty()) {
      throw new PartnerSyncHandledException(
        'The current partner contact could not be found.'
      );
    }

    return contacts[0];
  }

  /**
   * Checks whether the running user is an internal (Standard) user rather
   * than a partner community user.
   *
   * @return True if the running user's UserType is Standard.
   */
  public static Boolean isInternalUser() {
    if (
      Test.isRunningTest() &&
      testPartnerAccountIdsByUser.containsKey(UserInfo.getUserId())
    )
      return false;
    if (internalUserOverride != null)
      return internalUserOverride;
    User currentUser = [
      SELECT Id, UserType
      FROM User
      WHERE Id = :UserInfo.getUserId()
      WITH USER_MODE
      LIMIT 1
    ];

    return currentUser.UserType == 'Standard';
  }

  /**
   * Checks whether the running user is an external partner community user.
   *
   * @return True if the running user is not an internal user.
   */
  public static Boolean isExternalUser() {
    return !isInternalUser();
  }

  /**
   * Throws a handled exception unless the running user is an internal
   * user.
   */
  public static void assertInternalUser() {
    if (!isInternalUser()) {
      throw new PartnerSyncHandledException(
        'Only internal users can perform this action.'
      );
    }
  }

  /**
   * Throws a handled exception unless the running user is internal or
   * belongs to the given partner account.
   *
   * @param partnerAccountId Id of the partner Account to check access
   * against.
   */
  public static void assertCurrentUserCanAccessPartnerAccount(
    Id partnerAccountId
  ) {
    if (partnerAccountId == null) {
      throw new PartnerSyncHandledException('Partner account is required.');
    }

    if (isInternalUser()) {
      return;
    }

    Id currentPartnerAccountId = getCurrentPartnerAccountId();

    if (currentPartnerAccountId != partnerAccountId) {
      throw new PartnerSyncHandledException('Record not accessible.');
    }
  }

  /*
   * Single source of truth for feature-level authorization decisions.
   * Record-scoped assert methods on PartnerRecordAccessService delegate to
   * these rather than duplicating the underlying checks.
   */

  /**
   * Checks whether the running user can view the given deal registration.
   *
   * @param dealId Id of the Deal_Registration__c to check.
   * @return True for internal users, or for external users whose partner
   * account owns the deal.
   */
  public static Boolean canViewDeal(Id dealId) {
    if (isInternalUser()) {
      return true;
    }

    if (dealId == null) {
      return false;
    }

    Deal_Registration__c deal = DealRegistrationSelector.selectById(dealId);
    Id currentPartnerAccountId = getCurrentPartnerAccountId();

    if (deal.Partner_Account__c == currentPartnerAccountId) {
      return true;
    }

    // A co-sell participant (Deal_Participant__c) isn't the deal's own
    // Partner_Account__c, but Sprint 38 grants them a working
    // Deal_Registration__Share via DealParticipantSharingService once
    // Active - this business-logic gate must also recognise them, or
    // every partner-facing deal endpoint rejects them before the query
    // (and its Salesforce share) is ever consulted.
    return DealParticipantSelector.hasActiveParticipant(
      dealId,
      currentPartnerAccountId
    );
  }

  /**
   * Checks whether the running user can edit the given deal registration.
   *
   * @param dealId Id of the Deal_Registration__c to check.
   * @return True if the user has deal-review permission.
   */
  public static Boolean canEditDeal(Id dealId) {
    return PartnerPermissionService.canReviewDeals();
  }

  /**
   * Checks whether the running user can approve the given MDF request.
   *
   * @param requestId Id of the MDF_Request__c to check.
   * @return True if the user has MDF-approve permission.
   */
  public static Boolean canApproveMDF(Id requestId) {
    return PartnerPermissionService.canApproveMdf();
  }

  /**
   * Checks whether the running user can view analytics.
   *
   * @return True for external users, or for internal users with internal
   * analytics access.
   */
  public static Boolean canViewAnalytics() {
    if (isInternalUser()) {
      return PartnerPermissionService.canAccessInternalAnalytics();
    }

    return true;
  }

  /**
   * Checks whether the running user can access the given partner content
   * item.
   *
   * @param contentId Id of the Partner_Content__c record to check.
   * @return True if the content is visible to the running user's partner
   * account, or the user is internal.
   */
  public static Boolean canAccessContent(Id contentId) {
    if (isInternalUser()) {
      return true;
    }

    if (contentId == null) {
      return false;
    }

    Id partnerAccountId = getCurrentPartnerAccountId();
    Account partner = PartnerContentSelector.selectPartnerVisibilityContext(
      partnerAccountId
    );
    Partner_Content__c content = PartnerContentSelector.selectById(contentId);

    return PartnerContentDomain.isVisibleToPartner(content, partner);
  }

  /**
   * Checks whether the running user can approve the given deal
   * registration.
   *
   * @param dealId Id of the Deal_Registration__c to check.
   * @return True if the user has deal-approve permission.
   */
  public static Boolean canApproveDeal(Id dealId) {
    return PartnerPermissionService.canApproveDeal();
  }

  /**
   * Checks whether the running user can submit MDF requests.
   *
   * @return True if the running user is an external partner user.
   */
  public static Boolean canSubmitMDF() {
    return isExternalUser();
  }

  // Unlike canSubmitMDF(), deal submission is additionally gated per-contact
  // via Contact.Can_Submit_Deals__c — not every contact on a partner account
  // is authorized to register deals, only ones an internal admin has flagged.
  /**
   * Checks whether the running user can submit deal registrations.
   *
   * @return True for internal users, or for external users whose contact
   * is flagged Can_Submit_Deals__c.
   */
  public static Boolean canSubmitDeal() {
    if (isInternalUser()) {
      return true;
    }

    return getCurrentPartnerContact().Can_Submit_Deals__c == true;
  }

  /**
   * Throws a handled exception unless the running user can submit deal
   * registrations.
   */
  public static void assertCanSubmitDeal() {
    if (!canSubmitDeal()) {
      throw new PartnerSyncHandledException(
        'This contact is not authorized to submit deal registrations.'
      );
    }
  }

  /**
   * Checks whether the running user can view the given lead.
   *
   * @param leadId Id of the Lead to check.
   * @return True for internal users, or for external users whose partner
   * account owns the lead.
   */
  public static Boolean canViewLead(Id leadId) {
    if (isInternalUser()) {
      return true;
    }

    if (leadId == null) {
      return false;
    }

    Lead lead = LeadDistributionSelector.selectInternalLead(leadId);

    return lead.Partner_Account__c == getCurrentPartnerAccountId();
  }

  /**
   * Checks whether the running user can accept the given lead.
   *
   * @param leadId Id of the Lead to check.
   * @return True if the user can view the lead.
   */
  public static Boolean canAcceptLead(Id leadId) {
    return canViewLead(leadId);
  }

  /**
   * Checks whether the running user can convert the given lead.
   *
   * @param leadId Id of the Lead to check.
   * @return True if the user can view the lead.
   */
  public static Boolean canConvertLead(Id leadId) {
    return canViewLead(leadId);
  }

  /**
   * Checks whether the running user can download the given partner content
   * item.
   *
   * @param contentId Id of the Partner_Content__c record to check.
   * @return True if the user can access the content and it has an
   * attached content document.
   */
  public static Boolean canDownloadContent(Id contentId) {
    if (!canAccessContent(contentId)) {
      return false;
    }

    Partner_Content__c content = PartnerContentSelector.selectById(contentId);

    return String.isNotBlank(content.Content_Document_Id__c);
  }

  /**
   * Checks whether AI features are enabled for the current tenant.
   *
   * @return True if AI is enabled per Tenant_Config__mdt.
   */
  public static Boolean canUseAI() {
    return TenantConfigService.isAiEnabled();
  }
}
