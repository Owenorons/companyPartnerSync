public with sharing class AIInsightSelector {
  public static List<AI_Insight__c> selectPartnerInsights(Id partnerAccountId) {
    SecurityUtil.assertReadable(AI_Insight__c.SObjectType);

    return [
      SELECT
        Id,
        Partner_Account__c,
        Feature_Name__c,
        Provider__c,
        Confidence__c,
        Insight_Text__c,
        Recommendation__c,
        Status__c,
        CreatedDate
      FROM AI_Insight__c
      WHERE
        Partner_Account__c = :partnerAccountId
        AND Status__c IN ('Generated', 'Reviewed', 'Accepted')
      ORDER BY CreatedDate DESC
      LIMIT 200
    ];
  }

  public static AI_Insight__c selectById(Id insightId) {
    SecurityUtil.assertReadable(AI_Insight__c.SObjectType);

    List<AI_Insight__c> rows = [
      SELECT Id, Partner_Account__c, Status__c
      FROM AI_Insight__c
      WHERE Id = :insightId
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('AI insight not found.');
    }

    return rows[0];
  }
}
