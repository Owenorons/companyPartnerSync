public with sharing class PartnerAIController {
  @AuraEnabled(cacheable=true)
  public static List<AIInsightDTO> getMyInsights() {
    return AIInsightService.getMyInsights();
  }
}
