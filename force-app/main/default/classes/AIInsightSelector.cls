public with sharing class AIInsightSelector {
  public static List<AI_Insight__c> selectPartnerInsights(Id partnerAccountId) {
    return [
      SELECT
        Id,
        Insight_Type__c,
        Score__c,
        Confidence__c,
        Recommendation__c,
        Summary__c,
        Generated_On__c
      FROM AI_Insight__c
      WHERE Partner_Account__c = :partnerAccountId AND Status__c = 'Active'
      ORDER BY Generated_On__c DESC
      LIMIT 100
    ];
  }
}
