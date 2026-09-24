/**
 * Selector layer for AI_Insight__c. selectPartnerInsights() backs the
 * partner-facing surfaces (portal insight list, next best actions) and
 * deliberately excludes Draft insights - see the status filter below.
 */
public with sharing class AIInsightSelector {
  /**
   * Selects a partner's accepted AI insights, most recent first.
   *
   * @param partnerAccountId Id of the partner Account to select insights for.
   * @return Accepted AI_Insight__c records for the partner, limited to 200.
   */
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

  /**
   * Selects the active AI feature configs available to generate an
   * insight against, ordered by display name.
   *
   * @return Active AI_Feature_Config__mdt records.
   */
  public static List<AI_Feature_Config__mdt> selectActiveFeatureTypes() {
    return [
      SELECT DeveloperName, Feature_Name__c
      FROM AI_Feature_Config__mdt
      WHERE Enabled__c = TRUE
      WITH SYSTEM_MODE
      ORDER BY Feature_Name__c ASC
    ];
  }

  /**
   * Selects a single AI insight by Id.
   *
   * @param insightId Id of the AI_Insight__c to select.
   * @return The matching AI_Insight__c record.
   */
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

  /**
   * Selects a partner's own AI insight requests, most recent first.
   *
   * @param partnerAccountId Id of the partner Account whose requests are queried.
   * @return AI_Insight_Request__c records for the partner, limited to 100.
   */
  public static List<AI_Insight_Request__c> selectRequestsForPartner(
    Id partnerAccountId
  ) {
    SecurityUtil.assertReadable(AI_Insight_Request__c.SObjectType);

    return [
      SELECT
        Id,
        Partner_Account__c,
        Insight_Type__c,
        Notes__c,
        Status__c,
        Requested_On__c
      FROM AI_Insight_Request__c
      WHERE Partner_Account__c = :partnerAccountId
      WITH USER_MODE
      ORDER BY Requested_On__c DESC
      LIMIT 100
    ];
  }

  /**
   * Selects requests awaiting internal action, oldest first.
   *
   * @return New AI_Insight_Request__c records, limited to 200.
   */
  public static List<AI_Insight_Request__c> selectPendingRequests() {
    SecurityUtil.assertReadable(AI_Insight_Request__c.SObjectType);

    return [
      SELECT
        Id,
        Partner_Account__c,
        Partner_Account__r.Name,
        Insight_Type__c,
        Notes__c,
        Status__c,
        Requested_On__c
      FROM AI_Insight_Request__c
      WHERE Status__c = 'New'
      WITH SYSTEM_MODE
      ORDER BY Requested_On__c ASC
      LIMIT 200
    ];
  }

  /**
   * Selects a single AI insight request by Id.
   *
   * @param requestId Id of the AI_Insight_Request__c to select.
   * @return The matching AI_Insight_Request__c record.
   */
  public static AI_Insight_Request__c selectRequestById(Id requestId) {
    SecurityUtil.assertReadable(AI_Insight_Request__c.SObjectType);

    List<AI_Insight_Request__c> rows = [
      SELECT Id, Partner_Account__c, Insight_Type__c, Status__c
      FROM AI_Insight_Request__c
      WHERE Id = :requestId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('AI insight request not found.');
    }

    return rows[0];
  }
}
