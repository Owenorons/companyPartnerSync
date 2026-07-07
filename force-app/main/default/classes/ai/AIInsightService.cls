public with sharing class AIInsightService {
  public static List<AIInsightDTO> getMyInsights() {
    if (!TenantConfigService.isAiEnabled()) {
      throw new PartnerSyncHandledException('AI insights are disabled.');
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    List<AIInsightDTO> results = new List<AIInsightDTO>();

    for (
      AI_Insight__c row : AIInsightSelector
        .selectPartnerInsights(partnerAccountId)
    ) {
      results.add(AIInsightDomain.toDTO(row));
    }

    return results;
  }
}
