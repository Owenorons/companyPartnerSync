/**
 * Selector layer for Partner_Incentive_Payment__c.
 */
public without sharing class IncentivePaymentSelector {
  /**
   * Locks and reads a single payment record by Id.
   *
   * @param paymentId Id of the payment to load.
   * @return The locked Partner_Incentive_Payment__c record.
   */
  public static Partner_Incentive_Payment__c selectForUpdate(Id paymentId) {
    List<Partner_Incentive_Payment__c> rows = [
      SELECT
        Id,
        Incentive__c,
        Partner_Account__c,
        Payment_Reference__c,
        Payment_System__c,
        External_Transaction_Id__c,
        CurrencyIsoCode,
        Amount__c,
        Status__c,
        Scheduled_On__c,
        Paid_On__c
      FROM Partner_Incentive_Payment__c
      WHERE Id = :paymentId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Incentive payment not found.');
    }
    return rows[0];
  }
}
