/*
 * Selector layer for AI_Insight__c. selectPartnerInsights() backs the
 * partner-facing surfaces (portal insight list, next best actions) and
 * deliberately excludes Draft insights - see the status filter below.
 */
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
        // Only human-accepted model output is partner-visible.
        AND Status__c = 'Accepted'
      WITH USER_MODE
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
      WITH USER_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('AI insight not found.');
    }

    return rows[0];
  }
}
