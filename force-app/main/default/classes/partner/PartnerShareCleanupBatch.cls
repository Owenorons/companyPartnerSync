/**
 * Scheduled/batch job that reaps Partner_Record_Share__c grants past their
 * Expiry_Date__c. Deliberately calls PartnerShareService.revokeExpiredAccess
 * rather than revokeAccess — the latter requires the interactive
 * manage-shares permission set, which the user/context that scheduled this
 * job may not hold; expiry itself is this job's authorization. Per-record
 * failures are caught and logged so one bad row doesn't block the rest of
 * the batch.
 */
public with sharing class PartnerShareCleanupBatch implements Database.Batchable<SObject>, Schedulable {
  /**
   * Batchable start: queries active Partner_Record_Share__c grants past
   * their expiry date.
   *
   * @param context The batch job's execution context.
   * @return A QueryLocator over the expired, still-active share grants.
   */
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

  /**
   * Batchable execute: revokes expired access for each share in the
   * batch scope, logging and continuing past any per-record failure.
   *
   * @param context The batch job's execution context.
   * @param scope The batch of expired Partner_Record_Share__c records to
   * process.
   */
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

  /**
   * Batchable finish: no post-processing is required after cleanup.
   *
   * @param context The batch job's execution context.
   */
  public void finish(Database.BatchableContext context) {
  }

  /**
   * Schedulable execute: launches the batch job on its scheduled cadence.
   *
   * @param context The scheduled job's execution context.
   */
  public void execute(SchedulableContext context) {
    Database.executeBatch(new PartnerShareCleanupBatch(), 100);
  }
}
