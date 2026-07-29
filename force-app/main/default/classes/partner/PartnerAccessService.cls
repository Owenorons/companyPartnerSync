/*
 * Identity and feature-level authorization for the current user: resolving
 * which partner account/contact they represent, whether they're internal
 * vs. external, and the canX() capability checks other services build on.
 * Distinct from PartnerRecordAccessService, which answers "can this user see
 * this specific record" rather than "can this user use this feature at all."
 */
public with sharing class PartnerAccessService {
  public static Id getCurrentPartnerAccountId() {
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

  public static Contact getCurrentPartnerContact() {
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
      SELECT Id, AccountId, Name, Email, Phone
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

  public static Boolean isInternalUser() {
    User currentUser = [
      SELECT Id, UserType
      FROM User
      WHERE Id = :UserInfo.getUserId()
      WITH USER_MODE
      LIMIT 1
    ];

    return currentUser.UserType == 'Standard';
  }

  public static Boolean isExternalUser() {
    return !isInternalUser();
  }

  public static void assertInternalUser() {
    if (!isInternalUser()) {
      throw new PartnerSyncHandledException(
        'Only internal users can perform this action.'
      );
    }
  }

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

  public static Boolean canViewDeal(Id dealId) {
    if (isInternalUser()) {
      return true;
    }

    if (dealId == null) {
      return false;
    }

    Deal_Registration__c deal = DealRegistrationSelector.selectById(dealId);

    return deal.Partner_Account__c == getCurrentPartnerAccountId();
  }

  public static Boolean canEditDeal(Id dealId) {
    return PartnerPermissionService.canReviewDeals();
  }

  public static Boolean canApproveMDF(Id requestId) {
    return PartnerPermissionService.canApproveMdf();
  }

  public static Boolean canViewAnalytics() {
    if (isInternalUser()) {
      return PartnerPermissionService.canAccessInternalAnalytics();
    }

    return true;
  }

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

  public static Boolean canApproveDeal(Id dealId) {
    return PartnerPermissionService.canApproveDeal();
  }

  public static Boolean canSubmitMDF() {
    return isExternalUser();
  }

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

  public static Boolean canAcceptLead(Id leadId) {
    return canViewLead(leadId);
  }

  public static Boolean canConvertLead(Id leadId) {
    return canViewLead(leadId);
  }

  public static Boolean canDownloadContent(Id contentId) {
    if (!canAccessContent(contentId)) {
      return false;
    }

    Partner_Content__c content = PartnerContentSelector.selectById(contentId);

    return String.isNotBlank(content.Content_Document_Id__c);
  }

  public static Boolean canUseAI() {
    return TenantConfigService.isAiEnabled();
  }
}
