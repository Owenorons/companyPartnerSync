/**
 * Selector layer for Revenue_Reconciliation__c.
 */
public without sharing class RevenueReconciliationSelector {
  /**
   * Locks and reads a single reconciliation record by Id.
   *
   * @param reconciliationId Id of the reconciliation record to load.
   * @return The locked Revenue_Reconciliation__c record.
   */
  public static Revenue_Reconciliation__c selectForUpdate(Id reconciliationId) {
    List<Revenue_Reconciliation__c> rows = [
      SELECT
        Id,
        Revenue__c,
        Status__c,
        Candidate_Deal__c,
        Candidate_Opportunity__c,
        Match_Method__c,
        Match_Score__c,
        Assigned_To__c,
        Resolution__c,
        Resolution_Reason__c
      FROM Revenue_Reconciliation__c
      WHERE Id = :reconciliationId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException(
        'Revenue reconciliation not found.'
      );
    }
    return rows[0];
  }

  /**
   * Queries every open reconciliation row, most recently created first.
   *
   * @return Up to 200 open reconciliation records.
   */
  public static List<Revenue_Reconciliation__c> selectOpen() {
    return [
      SELECT
        Id,
        Revenue__c,
        Status__c,
        Candidate_Deal__c,
        Candidate_Opportunity__c,
        Match_Method__c,
        Assigned_To__c
      FROM Revenue_Reconciliation__c
      WHERE Status__c IN ('Open', 'Manual Review Required')
      WITH SYSTEM_MODE
      ORDER BY CreatedDate DESC
      LIMIT 200
    ];
  }
}
