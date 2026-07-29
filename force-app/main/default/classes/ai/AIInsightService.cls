/*
 * Partner-facing insight list service (portal Insight component). Wraps
 * AIInsightSelector + AIInsightDomain behind the tenant AI feature flag.
 */
public with sharing class AIInsightService {
  public static List<AIInsightDTO> getMyInsights() {
    if (!TenantConfigService.isAiEnabled()) {
      throw new PartnerSyncHandledException('AI insights are disabled.');
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    List<AIInsightDTO> results = new List<AIInsightDTO>();

    List<AI_Insight__c> insights = AIInsightSelector.selectPartnerInsights(
      partnerAccountId
    );
    for (AI_Insight__c row : insights) {
      results.add(AIInsightDomain.toDTO(row));
    }

    return results;
  }
}
