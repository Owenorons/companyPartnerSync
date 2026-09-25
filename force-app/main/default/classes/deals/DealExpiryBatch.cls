/**
 * Scheduled/batch job that expires active Deal_Protection_Grant__c records
 * past their End_Date__c, via DealProtectionCommandService rather than
 * DealReviewService.processDecision() — the latter requires the interactive
 * reviewer permission set, which the user/context that scheduled this job
 * may not hold; expiry itself is this job's authorization.
 * Per-record failures are caught and logged so one bad row doesn't block the
 * rest of the batch.
 */
public with sharing class DealExpiryBatch implements Database.Batchable<SObject>, Schedulable {
  /**
   * Builds the query locator for active protection grants that are past their end date.
   *
   * @param context Batch execution context (unused).
   * @return A query locator over active, current Deal_Protection_Grant__c rows past their end date.
   */
  public Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator(
      [
        SELECT Id, Deal__c, Version_Number__c
        FROM Deal_Protection_Grant__c
        WHERE
          Status__c = 'Active'
          AND Current__c = TRUE
          AND End_Date__c < :Date.today()
      ]
    );
  }

  /**
   * Expires each protection grant in scope via DealProtectionCommandService, logging and
   * continuing past any single record's failure rather than failing the whole batch.
   *
   * @param context Batch execution context (unused).
   * @param scope Batch of expired, active protection grants to process.
   */
  public void execute(
    Database.BatchableContext context,
    List<Deal_Protection_Grant__c> scope
  ) {
    for (Deal_Protection_Grant__c grant : scope) {
      try {
        DealProtectionCommand command = new DealProtectionCommand();
        command.dealId = grant.Deal__c;
        command.action = 'Expire Protection';
        command.commandKey = 'scheduled-expiry-' + grant.Id;
        command.expectedVersion = Integer.valueOf(grant.Version_Number__c);
        DealProtectionCommandService.execute(command);
      } catch (Exception ex) {
        LoggingService.error(
          'DealExpiryBatch',
          'Failed to expire protection grant ' + grant.Id,
          ex
        );
      }
    }
  }

  /**
   * No post-processing is required after this batch runs.
   *
   * @param context Batch execution context (unused).
   */
  public void finish(Database.BatchableContext context) {
  }

  /**
   * Scheduled entry point: launches this class as a batch job with a chunk size of 100.
   *
   * @param context Scheduled execution context (unused).
   */
  public void execute(SchedulableContext context) {
    Database.executeBatch(new DealExpiryBatch(), 100);
  }
}
