/**
 * Selector layer for Partner_Revenue_Dispute__c.
 */
public without sharing class RevenueDisputeSelector {
  /**
   * Locks and reads a single dispute record by Id.
   *
   * @param disputeId Id of the dispute to load.
   * @return The locked Partner_Revenue_Dispute__c record.
   */
  public static Partner_Revenue_Dispute__c selectForUpdate(Id disputeId) {
    List<Partner_Revenue_Dispute__c> rows = [
      SELECT
        Id,
        Partner_Account__c,
        Deal__c,
        Revenue__c,
        Revenue_Attribution__c,
        Incentive__c,
        Dispute_Type__c,
        Status__c,
        Description__c,
        Requested_Adjustment__c,
        Submitted_On__c,
        Assigned_To__c,
        Resolution__c,
        Resolved_On__c,
        Resolved_By__c
      FROM Partner_Revenue_Dispute__c
      WHERE Id = :disputeId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Revenue dispute not found.');
    }
    return rows[0];
  }
}
