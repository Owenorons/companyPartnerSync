/**
 * Scheduled/batch job that reminds partners of certifications nearing
 * expiry and expires ones that have passed. Queries every Completed
 * Partner_Training_Assignment__c due to expire within 30 days: an
 * assignment already past Expires_On__c is flipped to 'Expired' and fires a
 * 'CertificationExpired' event; one expiring in exactly 30 days fires a
 * 'CertificationExpiringSoon' reminder with no status change - the exact
 * (not <=) day check is what makes the reminder fire once per assignment
 * without needing a separate "already reminded" field. Per-record failures
 * are caught and logged so one bad row doesn't block the rest of the batch.
 */
public with sharing class PartnerCertificationReminderBatch implements Database.Batchable<SObject>, Schedulable {
  private static final Integer REMINDER_WINDOW_DAYS = 30;

  /**
   * Builds the query locator for Completed training assignments due to expire within the
   * reminder window (including ones already past expiry).
   *
   * @param context Batch execution context (unused).
   * @return A query locator over in-window Partner_Training_Assignment__c rows.
   */
  public Database.QueryLocator start(Database.BatchableContext context) {
    Date windowEnd = Date.today().addDays(REMINDER_WINDOW_DAYS);
    return Database.getQueryLocator(
      [
        SELECT
          Id,
          Status__c,
          Expires_On__c,
          Partner_Account__c,
          Onboarding__r.Partner_Account__c
        FROM Partner_Training_Assignment__c
        WHERE
          Status__c = 'Completed'
          AND Expires_On__c != NULL
          AND Expires_On__c <= :windowEnd
      ]
    );
  }

  /**
   * Expires each past-due assignment and fires a reminder for each assignment expiring in
   * exactly 30 days, logging and continuing past any single record's failure rather than
   * failing the whole batch.
   *
   * @param context Batch execution context (unused).
   * @param scope Batch of in-window Partner_Training_Assignment__c rows to process.
   */
  public void execute(
    Database.BatchableContext context,
    List<Partner_Training_Assignment__c> scope
  ) {
    Date today = Date.today();
    Date reminderDay = today.addDays(REMINDER_WINDOW_DAYS);

    for (Partner_Training_Assignment__c assignment : scope) {
      try {
        Id partnerAccountId = assignment.Partner_Account__c != null
          ? assignment.Partner_Account__c
          : assignment.Onboarding__r?.Partner_Account__c;

        if (assignment.Expires_On__c < today) {
          assignment.Status__c = 'Expired';
          Database.update(assignment, AccessLevel.SYSTEM_MODE);
          PlatformEventPublisherService.publish(
            'CertificationExpired',
            assignment.Id,
            'Partner_Training_Assignment__c',
            partnerAccountId,
            'A partner certification has expired.',
            'Warning'
          );
        } else if (assignment.Expires_On__c == reminderDay) {
          PlatformEventPublisherService.publish(
            'CertificationExpiringSoon',
            assignment.Id,
            'Partner_Training_Assignment__c',
            partnerAccountId,
            'A partner certification expires in 30 days.',
            'Info'
          );
        }
      } catch (Exception ex) {
        LoggingService.error(
          'PartnerCertificationReminderBatch',
          'Failed to process training assignment ' + assignment.Id,
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
    Database.executeBatch(new PartnerCertificationReminderBatch(), 100);
  }
}
