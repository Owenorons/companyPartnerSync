/**
 * Central "can this partner see this specific record" gate. Each
 * assertPartnerAccessTo* method covers one object type and encapsulates
 * whatever reachability rule applies to it (ownership match, sharing lookup,
 * or delegating to a selector that already scopes to the partner) —
 * internal users are always exempt. Callers use this instead of
 * re-implementing the visibility check per object.
 */
public with sharing class PartnerRecordAccessService {
  /**
   * Throws a handled exception unless the running user is internal or
   * belongs to the given partner account.
   *
   * @param partnerAccountId Id of the partner Account to check access to.
   */
  public static void assertPartnerAccessToAccount(Id partnerAccountId) {
    if (PartnerAccessService.isInternalUser()) {
      return;
    }

    Id currentPartnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    if (
      partnerAccountId == null ||
      partnerAccountId != currentPartnerAccountId
    ) {
      throw new PartnerSyncHandledException('Record not accessible.');
    }
  }

  /**
   * Throws a handled exception unless the running user can view the given
   * lead.
   *
   * @param leadId Id of the Lead to check access to.
   */
  public static void assertPartnerAccessToLead(Id leadId) {
    if (!PartnerAccessService.canViewLead(leadId)) {
      throw new PartnerSyncHandledException('Lead not accessible.');
    }
  }

  /**
   * Throws a handled exception unless the running user can view the given
   * deal registration.
   *
   * @param dealId Id of the Deal_Registration__c to check access to.
   */
  public static void assertPartnerAccessToDeal(Id dealId) {
    if (!PartnerAccessService.canViewDeal(dealId)) {
      throw new PartnerSyncHandledException('Deal not accessible.');
    }
  }

  /**
   * Throws a handled exception unless the given MDF request is accessible
   * to the running user's partner account (internal users are always
   * exempt).
   *
   * @param requestId Id of the MDF_Request__c to check access to.
   */
  public static void assertPartnerAccessToMdf(Id requestId) {
    if (PartnerAccessService.isInternalUser()) {
      return;
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    MDFSelector.selectForPartner(requestId, partnerAccountId);
  }

  /**
   * Throws a handled exception unless the given notification is
   * accessible to the running user (internal users are always exempt).
   *
   * @param notificationId Id of the notification record to check access
   * to.
   */
  public static void assertPartnerAccessToNotification(Id notificationId) {
    if (PartnerAccessService.isInternalUser()) {
      return;
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();
    Id userId = UserInfo.getUserId();

    NotificationSelector.selectAccessibleNotification(
      notificationId,
      partnerAccountId,
      userId
    );
  }

  /**
   * Throws a handled exception unless the running user can access the
   * given partner content item.
   *
   * @param contentId Id of the Partner_Content__c record to check access
   * to.
   */
  public static void assertPartnerAccessToContent(Id contentId) {
    if (!PartnerAccessService.canAccessContent(contentId)) {
      throw new PartnerSyncHandledException('Content not accessible.');
    }
  }

  /**
   * Throws a handled exception unless the given AI insight belongs to the
   * running user's partner account (internal users are always exempt).
   *
   * @param insightId Id of the AI_Insight__c record to check access to.
   */
  public static void assertPartnerAccessToAIInsight(Id insightId) {
    if (PartnerAccessService.isInternalUser()) {
      return;
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();
    AI_Insight__c insight = AIInsightSelector.selectById(insightId);

    if (insight.Partner_Account__c != partnerAccountId) {
      throw new PartnerSyncHandledException('AI insight not accessible.');
    }
  }
}
