/*
 * Scheduled/batch job that expires Deal_Registration__c records past their
 * Protection_End_Date__c. Deliberately calls DealReviewService.expireProtection
 * rather than routing through processDecision() — the latter requires the
 * interactive reviewer permission set, which the user/context that scheduled
 * this job may not hold; expiry itself is this job's authorization.
 * Per-record failures are caught and logged so one bad row doesn't block the
 * rest of the batch.
 */
public with sharing class DealExpiryBatch implements Database.Batchable<SObject>, Schedulable {
  public Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator(
      [
        SELECT Id
        FROM Deal_Registration__c
        WHERE
          Status__c = 'Approved'
          AND Protection_End_Date__c != NULL
          AND Protection_End_Date__c < :Date.today()
      ]
    );
  }

  public void execute(
    Database.BatchableContext context,
    List<Deal_Registration__c> scope
  ) {
    for (Deal_Registration__c deal : scope) {
      try {
        DealReviewService.expireProtection(deal.Id);
      } catch (Exception ex) {
        LoggingService.error(
          'DealExpiryBatch',
          'Failed to expire deal registration ' + deal.Id,
          ex
        );
      }
    }
  }

  public void finish(Database.BatchableContext context) {
  }

  public void execute(SchedulableContext context) {
    Database.executeBatch(new DealExpiryBatch(), 100);
  }
}
