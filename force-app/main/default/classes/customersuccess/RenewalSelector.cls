/**
 * Selector layer for Partner_Renewal__c.
 */
public without sharing class RenewalSelector {
  /**
   * Locks and reads a single renewal record by Id.
   *
   * @param renewalId Id of the renewal to load.
   * @return The locked Partner_Renewal__c record.
   */
  public static Partner_Renewal__c selectForUpdate(Id renewalId) {
    List<Partner_Renewal__c> rows = [
      SELECT
        Id,
        Customer_Success_Engagement__c,
        Customer_Account__c,
        Original_Deal__c,
        Current_Deal__c,
        Current_Opportunity__c,
        Primary_Partner__c,
        Original_Protection__c,
        Commercial_Entitlement__c,
        Status__c,
        Renewal_Health__c,
        Planning_Window_Start_On__c,
        Target_Decision_On__c,
        Partner_Continuity_Policy__c,
        Confirmed_On__c,
        Declined_On__c,
        Material_Change__c,
        Material_Change_Reason__c,
        Version_Number__c
      FROM Partner_Renewal__c
      WHERE Id = :renewalId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Partner renewal not found.');
    }

    return rows[0];
  }

  /**
   * Checks whether a renewal has already been identified for a given
   * commercial entitlement, so RenewalIdentificationBatch stays idempotent
   * across repeated runs.
   *
   * @param entitlementId Id of the commercial entitlement.
   * @return True if a non-terminal renewal already exists for this entitlement.
   */
  public static Boolean hasOpenRenewalForEntitlement(Id entitlementId) {
    return [
        SELECT COUNT()
        FROM Partner_Renewal__c
        WHERE
          Commercial_Entitlement__c = :entitlementId
          AND Status__c NOT IN ('Not Renewed', 'Churned', 'Cancelled')
        WITH SYSTEM_MODE
      ] > 0;
  }

  /**
   * Bulk counterpart to hasOpenRenewalForEntitlement(): one query for a
   * whole chunk of entitlement Ids instead of one query per entitlement -
   * for RenewalIdentificationBatch, which must not issue a SOQL call per
   * row.
   *
   * @param entitlementIds Ids of the commercial entitlements to check.
   * @return The subset of entitlementIds that already have a non-terminal renewal.
   */
  public static Set<Id> selectEntitlementIdsWithOpenRenewal(
    Set<Id> entitlementIds
  ) {
    Set<Id> withOpenRenewal = new Set<Id>();
    for (Partner_Renewal__c renewal : [
      SELECT Commercial_Entitlement__c
      FROM Partner_Renewal__c
      WHERE
        Commercial_Entitlement__c IN :entitlementIds
        AND Status__c NOT IN ('Not Renewed', 'Churned', 'Cancelled')
      WITH SYSTEM_MODE
    ]) {
      withOpenRenewal.add(renewal.Commercial_Entitlement__c);
    }
    return withOpenRenewal;
  }
}
