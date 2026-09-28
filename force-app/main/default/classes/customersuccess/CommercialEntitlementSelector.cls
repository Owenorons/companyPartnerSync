/**
 * Selector layer for Customer_Commercial_Entitlement__c.
 */
public without sharing class CommercialEntitlementSelector {
  /**
   * Locks and reads a single entitlement record by Id.
   *
   * @param entitlementId Id of the entitlement to load.
   * @return The locked Customer_Commercial_Entitlement__c record.
   */
  public static Customer_Commercial_Entitlement__c selectForUpdate(
    Id entitlementId
  ) {
    List<Customer_Commercial_Entitlement__c> rows = [
      SELECT
        Id,
        Customer_Account__c,
        Customer_Success_Engagement__c,
        Originating_Deal__c,
        Originating_Opportunity__c,
        Product__c,
        Product_Family__c,
        Entitlement_Type__c,
        Effective_Start_On__c,
        Effective_End_On__c,
        Quantity__c,
        Status__c,
        Auto_Renew__c,
        Version_Number__c
      FROM Customer_Commercial_Entitlement__c
      WHERE Id = :entitlementId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException(
        'Customer commercial entitlement not found.'
      );
    }

    return rows[0];
  }

  /**
   * Queries every Active entitlement entering a renewal planning window
   * (Effective_End_On__c between today and today + windowDays), for
   * RenewalIdentificationBatch.
   *
   * @param windowDays How many days ahead of expiry counts as "entering the window".
   * @return Active entitlements whose Effective_End_On__c falls within the window.
   */
  public static List<Customer_Commercial_Entitlement__c> selectEnteringRenewalWindow(
    Integer windowDays
  ) {
    Date today = System.today();
    Date windowEnd = today.addDays(windowDays);
    return [
      SELECT
        Id,
        Customer_Account__c,
        Customer_Success_Engagement__c,
        Originating_Deal__c,
        Product_Family__c,
        Effective_End_On__c
      FROM Customer_Commercial_Entitlement__c
      WHERE
        Status__c = 'Active'
        AND Effective_End_On__c != NULL
        AND Effective_End_On__c >= :today
        AND Effective_End_On__c <= :windowEnd
      WITH SYSTEM_MODE
    ];
  }
}
