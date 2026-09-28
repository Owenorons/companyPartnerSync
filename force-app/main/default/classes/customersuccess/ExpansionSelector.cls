/**
 * Selector layer for Partner_Expansion__c.
 */
public without sharing class ExpansionSelector {
  /**
   * Locks and reads a single expansion record by Id.
   *
   * @param expansionId Id of the expansion to load.
   * @return The locked Partner_Expansion__c record.
   */
  public static Partner_Expansion__c selectForUpdate(Id expansionId) {
    List<Partner_Expansion__c> rows = [
      SELECT
        Id,
        Customer_Success_Engagement__c,
        Customer_Account__c,
        Originating_Deal__c,
        Primary_Partner__c,
        Expansion_Type__c,
        Status__c,
        Description__c,
        Resulting_Deal__c,
        Identified_On__c,
        Qualified_On__c,
        Version_Number__c
      FROM Partner_Expansion__c
      WHERE Id = :expansionId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Partner expansion not found.');
    }

    return rows[0];
  }
}
