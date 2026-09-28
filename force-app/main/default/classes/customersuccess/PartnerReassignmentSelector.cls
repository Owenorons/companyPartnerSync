/**
 * Selector layer for Partner_Reassignment__c.
 */
public without sharing class PartnerReassignmentSelector {
  /**
   * Locks and reads a single reassignment record by Id.
   *
   * @param reassignmentId Id of the reassignment to load.
   * @return The locked Partner_Reassignment__c record.
   */
  public static Partner_Reassignment__c selectForUpdate(Id reassignmentId) {
    List<Partner_Reassignment__c> rows = [
      SELECT
        Id,
        Target_Object__c,
        Target_Record_Id__c,
        Current_Partner__c,
        Requested_Partner__c,
        Reason__c,
        Status__c,
        Requested_By__c,
        Approved_By__c,
        Approved_On__c,
        Version_Number__c
      FROM Partner_Reassignment__c
      WHERE Id = :reassignmentId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Partner reassignment not found.');
    }

    return rows[0];
  }
}
