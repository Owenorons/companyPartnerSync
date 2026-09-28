/**
 * Selector layer for Deal_Revenue__c.
 */
public without sharing class RevenueSelector {
  /**
   * Locks and reads a single revenue record by Id.
   *
   * @param revenueId Id of the revenue record to load.
   * @return The locked Deal_Revenue__c record.
   */
  public static Deal_Revenue__c selectForUpdate(Id revenueId) {
    List<Deal_Revenue__c> rows = [
      SELECT
        Id,
        Deal__c,
        Opportunity__c,
        Deal_Opportunity__c,
        Implementation__c,
        Customer_Account__c,
        Partner_Account__c,
        Source_Revenue__c,
        Reversal_Of__c,
        Revenue_Type__c,
        Status__c,
        Payment_Status__c,
        Gross_Amount__c,
        Net_Amount__c,
        Eligible_Amount__c,
        CurrencyIsoCode,
        Revenue_Date__c,
        Source_Type__c,
        External_Revenue_Key__c,
        Version_Number__c
      FROM Deal_Revenue__c
      WHERE Id = :revenueId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Revenue record not found.');
    }
    return rows[0];
  }

  /**
   * Looks up a revenue record by its idempotency key.
   *
   * @param externalRevenueKey The External_Revenue_Key__c value to match.
   * @return The matching Deal_Revenue__c, or null if none exists.
   */
  public static Deal_Revenue__c selectByExternalKey(String externalRevenueKey) {
    if (String.isBlank(externalRevenueKey)) {
      return null;
    }
    List<Deal_Revenue__c> rows = [
      SELECT Id, Deal__c, Status__c, Version_Number__c
      FROM Deal_Revenue__c
      WHERE External_Revenue_Key__c = :externalRevenueKey
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    return rows.isEmpty() ? null : rows[0];
  }

  /**
   * Queries every revenue record for a deal, most recent first.
   *
   * @param dealId Id of the deal.
   * @return The deal's revenue records.
   */
  public static List<Deal_Revenue__c> selectForDeal(Id dealId) {
    return [
      SELECT
        Id,
        Deal__c,
        Revenue_Type__c,
        Status__c,
        Gross_Amount__c,
        Net_Amount__c,
        CurrencyIsoCode,
        Revenue_Date__c,
        Version_Number__c
      FROM Deal_Revenue__c
      WHERE Deal__c = :dealId
      WITH SYSTEM_MODE
      ORDER BY CreatedDate DESC
    ];
  }
}
