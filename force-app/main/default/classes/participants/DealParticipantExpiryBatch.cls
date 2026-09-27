/**
 * Scheduled/batch job for Invited/Accepted Deal_Participant__c invitations
 * approaching or past their Respond_By__c: expires overdue ones (via
 * DealParticipantCommandService, not direct DML - modeled directly on
 * DealExpiryBatch) and flags/notifies ones that have crossed their SLA
 * warning threshold exactly once (At_Risk_Notified__c). Per-record
 * failures are caught and logged so one bad row doesn't block the rest of
 * the batch.
 */
public with sharing class DealParticipantExpiryBatch implements Database.Batchable<SObject>, Schedulable {
  /**
   * Builds the query locator for Invited/Accepted participants with a
   * response deadline set - both overdue and approaching.
   *
   * @param context Batch execution context (unused).
   * @return A query locator over in-scope Deal_Participant__c rows.
   */
  public Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator(
      [
        SELECT
          Id,
          Version_Number__c,
          Participant_Type__c,
          Invited_On__c,
          Respond_By__c,
          Deal__c,
          Partner_Account__c,
          At_Risk_Notified__c
        FROM Deal_Participant__c
        WHERE Status__c IN ('Invited', 'Accepted') AND Respond_By__c != NULL
      ]
    );
  }

  /**
   * Expires each overdue participant via DealParticipantCommandService,
   * and flags/notifies each not-yet-overdue one that has newly crossed
   * its SLA warning threshold.
   *
   * @param context Batch execution context (unused).
   * @param scope Batch of in-scope Deal_Participant__c rows to process.
   */
  public void execute(
    Database.BatchableContext context,
    List<Deal_Participant__c> scope
  ) {
    Datetime now = System.now();
    List<Deal_Participant__c> newlyAtRisk = new List<Deal_Participant__c>();

    for (Deal_Participant__c participant : scope) {
      try {
        if (participant.Respond_By__c < now) {
          DealParticipantCommand command = new DealParticipantCommand();
          command.participantId = participant.Id;
          command.action = 'Expire';
          command.expectedVersion = Integer.valueOf(
            participant.Version_Number__c
          );
          DealParticipantCommandService.execute(command);
        } else if (
          participant.At_Risk_Notified__c != true &&
          DealParticipantSlaService.isAtRisk(
            participant.Participant_Type__c,
            participant.Invited_On__c,
            participant.Respond_By__c,
            now
          )
        ) {
          newlyAtRisk.add(participant);
        }
      } catch (Exception ex) {
        LoggingService.error(
          'DealParticipantExpiryBatch',
          'Failed to process participant ' + participant.Id,
          ex
        );
      }
    }

    if (!newlyAtRisk.isEmpty()) {
      flagAndNotifyAtRisk(newlyAtRisk);
    }
  }

  private void flagAndNotifyAtRisk(List<Deal_Participant__c> participants) {
    List<Deal_Participant__c> updates = new List<Deal_Participant__c>();
    for (Deal_Participant__c participant : participants) {
      updates.add(
        new Deal_Participant__c(Id = participant.Id, At_Risk_Notified__c = true)
      );
    }

    try {
      Database.update(updates, AccessLevel.SYSTEM_MODE);
    } catch (Exception ex) {
      LoggingService.error(
        'DealParticipantExpiryBatch',
        'Failed to flag at-risk participants.',
        ex
      );
      return;
    }

    for (Deal_Participant__c participant : participants) {
      PlatformEventPublisherService.publish(
        'DealParticipantInvitationAtRisk',
        participant.Deal__c,
        'Deal_Registration__c',
        participant.Partner_Account__c,
        'A co-sell invitation is approaching its response deadline.',
        'Warning'
      );
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
