/**
 * Partner-facing insight list service (portal Insight component). Wraps
 * AIInsightSelector + AIInsightDomain behind the tenant AI feature flag.
 */
public with sharing class AIInsightService {
  /**
   * Lists the running partner user's accepted AI insights, throwing if
   * AI insights are disabled tenant-wide.
   *
   * @return AI insights for the running user's partner account.
   */
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
