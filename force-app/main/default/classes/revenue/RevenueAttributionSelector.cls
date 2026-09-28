/**
 * Selector layer for Deal_Revenue_Attribution__c.
 */
public without sharing class RevenueAttributionSelector {
  /**
   * Locks and reads a single attribution record by Id.
   *
   * @param attributionId Id of the attribution record to load.
   * @return The locked Deal_Revenue_Attribution__c record.
   */
  public static Deal_Revenue_Attribution__c selectForUpdate(Id attributionId) {
    List<Deal_Revenue_Attribution__c> rows = [
      SELECT
        Id,
        Revenue__c,
        Deal__c,
        Deal_Participant__c,
        Partner_Account__c,
        Attribution_Type__c,
        Attribution_Percentage__c,
        Attributed_Amount__c,
        Status__c,
        Calculation_Snapshot__c,
        Override__c,
        Version_Number__c
      FROM Deal_Revenue_Attribution__c
      WHERE Id = :attributionId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Revenue attribution not found.');
    }
    return rows[0];
  }

  /**
   * Queries every attribution row for a revenue record.
   *
   * @param revenueId Id of the revenue record.
   * @return The revenue's attribution rows.
   */
  public static List<Deal_Revenue_Attribution__c> selectForRevenue(
    Id revenueId
  ) {
    return [
      SELECT
        Id,
        Partner_Account__c,
        Attribution_Type__c,
        Attribution_Percentage__c,
        Attributed_Amount__c,
        Status__c
      FROM Deal_Revenue_Attribution__c
      WHERE Revenue__c = :revenueId
      WITH SYSTEM_MODE
    ];
  }
}
