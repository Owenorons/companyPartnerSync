/**
 * Scheduled/batch job that expires Invited/Accepted Deal_Participant__c
 * invitations past their Respond_By__c, via DealParticipantCommandService
 * rather than direct DML - modeled directly on DealExpiryBatch. Per-record
 * failures are caught and logged so one bad row doesn't block the rest of
 * the batch.
 */
public with sharing class DealParticipantExpiryBatch implements Database.Batchable<SObject>, Schedulable {
  /**
   * Builds the query locator for Invited/Accepted participants past their
   * response deadline.
   *
   * @param context Batch execution context (unused).
   * @return A query locator over overdue Deal_Participant__c rows.
   */
  public Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator(
      [
        SELECT Id, Version_Number__c
        FROM Deal_Participant__c
        WHERE
          Status__c IN ('Invited', 'Accepted')
          AND Respond_By__c != NULL
          AND Respond_By__c < :System.now()
      ]
    );
  }

  /**
   * Expires each overdue participant in scope via DealParticipantCommandService.
   *
   * @param context Batch execution context (unused).
   * @param scope Batch of overdue Deal_Participant__c rows to process.
   */
  public void execute(
    Database.BatchableContext context,
    List<Deal_Participant__c> scope
  ) {
    for (Deal_Participant__c participant : scope) {
      try {
        DealParticipantCommand command = new DealParticipantCommand();
        command.participantId = participant.Id;
        command.action = 'Expire';
        command.expectedVersion = Integer.valueOf(
          participant.Version_Number__c
        );
        DealParticipantCommandService.execute(command);
      } catch (Exception ex) {
        LoggingService.error(
          'DealParticipantExpiryBatch',
          'Failed to expire participant ' + participant.Id,
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
   * Scheduled entry point: launches this class as a batch job with a chunk
   * size of 100.
   *
   * @param context Scheduled execution context (unused).
   */
  public void execute(SchedulableContext context) {
    Database.executeBatch(new DealParticipantExpiryBatch(), 100);
  }
}
