/**
 * Selector layer for Partner_Incentive__c.
 */
public without sharing class IncentiveSelector {
  /**
   * Locks and reads a single incentive record by Id.
   *
   * @param incentiveId Id of the incentive to load.
   * @return The locked Partner_Incentive__c record.
   */
  public static Partner_Incentive__c selectForUpdate(Id incentiveId) {
    List<Partner_Incentive__c> rows = [
      SELECT
        Id,
        Deal__c,
        Revenue__c,
        Revenue_Attribution__c,
        Partner_Account__c,
        Deal_Participant__c,
        Protection__c,
        Incentive_Type__c,
        Status__c,
        Eligible_Base_Amount__c,
        Rate__c,
        Calculated_Amount__c,
        Approved_Amount__c,
        Paid_Amount__c,
        Eligibility_Date__c,
        Approval_Date__c,
        Payment_Date__c,
        Version_Number__c
      FROM Partner_Incentive__c
      WHERE Id = :incentiveId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Incentive not found.');
    }
    return rows[0];
  }

  /**
   * Finds an existing incentive already evaluated for a given attribution
   * row, if any - evaluate() is idempotent per attribution.
   *
   * @param revenueAttributionId Id of the Deal_Revenue_Attribution__c.
   * @return The existing Partner_Incentive__c, or null if none exists.
   */
  public static Partner_Incentive__c selectForAttribution(
    Id revenueAttributionId
  ) {
    List<Partner_Incentive__c> rows = [
      SELECT Id, Status__c, Version_Number__c
      FROM Partner_Incentive__c
      WHERE Revenue_Attribution__c = :revenueAttributionId
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    return rows.isEmpty() ? null : rows[0];
  }
}
