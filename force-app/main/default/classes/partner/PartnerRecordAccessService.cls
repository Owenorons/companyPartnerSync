/*
 * Central "can this partner see this specific record" gate. Each
 * assertPartnerAccessTo* method covers one object type and encapsulates
 * whatever reachability rule applies to it (ownership match, sharing lookup,
 * or delegating to a selector that already scopes to the partner) —
 * internal users are always exempt. Callers use this instead of
 * re-implementing the visibility check per object.
 */
public with sharing class PartnerRecordAccessService {
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

  public static void assertPartnerAccessToLead(Id leadId) {
    if (!PartnerAccessService.canViewLead(leadId)) {
      throw new PartnerSyncHandledException('Lead not accessible.');
    }
  }

  public static void assertPartnerAccessToDeal(Id dealId) {
    if (!PartnerAccessService.canViewDeal(dealId)) {
      throw new PartnerSyncHandledException('Deal not accessible.');
    }
  }

  public static void assertPartnerAccessToMdf(Id requestId) {
    if (PartnerAccessService.isInternalUser()) {
      return;
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    MDFSelector.selectForPartner(requestId, partnerAccountId);
  }

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

  public static void assertPartnerAccessToContent(Id contentId) {
    if (!PartnerAccessService.canAccessContent(contentId)) {
      throw new PartnerSyncHandledException('Content not accessible.');
    }
  }

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
