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
    if (PartnerAccessService.isInternalUser()) {
      return;
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    LeadDistributionSelector.selectPartnerLeadById(leadId, partnerAccountId);
  }

  public static void assertPartnerAccessToDeal(Id dealId) {
    if (PartnerAccessService.isInternalUser()) {
      return;
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();
    Deal_Registration__c deal = DealRegistrationSelector.selectById(dealId);

    if (deal.Partner_Account__c != partnerAccountId) {
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
    if (PartnerAccessService.isInternalUser()) {
      return;
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();
    Account partner = PartnerContentSelector.selectPartnerVisibilityContext(
      partnerAccountId
    );

    Partner_Content__c content = PartnerContentSelector.selectById(contentId);

    if (!PartnerContentDomain.isVisibleToPartner(content, partner)) {
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
