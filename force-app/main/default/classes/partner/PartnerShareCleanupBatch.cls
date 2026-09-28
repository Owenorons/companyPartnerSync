/**
 * Scheduled/batch job that reaps Partner_Record_Share__c grants past their
 * Expiry_Date__c. Deliberately calls PartnerShareService.
 * revokeParticipantAccessBulk() rather than the interactive revokeAccess()
 * (which requires the manage-shares permission set this job's context may
 * not hold - expiry itself is this job's authorization) or the per-record
 * revokeExpiredAccess() (which does 1 SOQL + 3 DML per row - at this
 * batch's 100-row chunk size that's 300 DML statements, over the
 * per-transaction limit, discovered during a pre-beta bulk-safety audit).
 * The bulk entry point's own per-record expiry check is skipped here
 * because this batch's own query WHERE clause already guarantees every
 * row in scope is expired.
 *
 * Trade-off: revokeParticipantAccessBulk()'s registry update is a single
 * all-or-nothing `update registries` DML, not partial-success - a single
 * row's DML failure (e.g. a validation rule) now fails the whole 100-row
 * chunk's revoke rather than only that row, a coarser failure mode than
 * the old per-row try/catch. This matches how every other bulk caller of
 * this same method already behaves (DealParticipantSharingService,
 * ImplementationParticipantSharingService) and is accepted here in
 * exchange for actually staying under governor limits; a failed chunk
 * simply retries whole on the next scheduled run.
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
   * Batchable execute: revokes expired access for the whole chunk in one
   * bulk call, logging and continuing rather than failing the batch if the
   * bulk revoke itself throws.
   *
   * @param context The batch job's execution context.
   * @param scope The batch of expired Partner_Record_Share__c records to
   * process.
   */
  public void execute(
    Database.BatchableContext context,
    List<Partner_Record_Share__c> scope
  ) {
    List<Id> shareIds = new List<Id>();
    for (Partner_Record_Share__c registry : scope) {
      shareIds.add(registry.Id);
    }

    try {
      PartnerShareService.revokeParticipantAccessBulk(shareIds);
    } catch (Exception ex) {
      LoggingService.error(
        'PartnerShareCleanupBatch',
        'Failed to revoke a chunk of expired shares.',
        ex
      );
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
