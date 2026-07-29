/*
 * Scheduled/batch job that reaps Partner_Record_Share__c grants past their
 * Expiry_Date__c. Deliberately calls PartnerShareService.revokeExpiredAccess
 * rather than revokeAccess — the latter requires the interactive
 * manage-shares permission set, which the user/context that scheduled this
 * job may not hold; expiry itself is this job's authorization. Per-record
 * failures are caught and logged so one bad row doesn't block the rest of
 * the batch.
 */
public with sharing class PartnerShareCleanupBatch implements Database.Batchable<SObject>, Schedulable {
  public Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator(
      [
        SELECT Id
        FROM Partner_Record_Share__c
        WHERE
          Active__c = TRUE
          AND Expiry_Date__c != NULL
          AND Expiry_Date__c < :Date.today()
      ]
    );
  }

  public void execute(
    Database.BatchableContext context,
    List<Partner_Record_Share__c> scope
  ) {
    for (Partner_Record_Share__c registry : scope) {
      try {
        PartnerShareService.revokeExpiredAccess(registry.Id);
      } catch (Exception ex) {
        LoggingService.error(
          'PartnerShareCleanupBatch',
          'Failed to revoke expired share ' + registry.Id,
          ex
        );
      }
    }
  }

  public void finish(Database.BatchableContext context) {
  }

  public void execute(SchedulableContext context) {
    Database.executeBatch(new PartnerShareCleanupBatch(), 100);
  }
}
