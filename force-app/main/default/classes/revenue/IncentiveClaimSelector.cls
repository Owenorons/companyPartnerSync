/**
 * Selector layer for Partner_Incentive_Claim__c.
 */
public without sharing class IncentiveClaimSelector {
  /**
   * Locks and reads a single claim record by Id.
   *
   * @param claimId Id of the claim to load.
   * @return The locked Partner_Incentive_Claim__c record.
   */
  public static Partner_Incentive_Claim__c selectForUpdate(Id claimId) {
    List<Partner_Incentive_Claim__c> rows = [
      SELECT
        Id,
        Incentive__c,
        Submitted_By__c,
        Submitted_On__c,
        Claimed_Amount__c,
        Claim_Reason__c,
        Evidence_Required__c,
        Evidence_Status__c,
        Status__c,
        Reviewed_By__c,
        Reviewed_On__c,
        Decision__c,
        Decision_Reason__c,
        Version_Number__c
      FROM Partner_Incentive_Claim__c
      WHERE Id = :claimId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Incentive claim not found.');
    }
    return rows[0];
  }
}
