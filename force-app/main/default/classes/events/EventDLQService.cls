/**
 * Dead-letter queue for platform event processing failures: when
 * PartnerSyncEventHandler catches an exception from a consumer, it lands
 * here instead of being lost, so it can be inspected/retried later.
 */
public with sharing class EventDLQService {
  @TestVisible
  private static final Integer MAX_RETRY_COUNT = 5;

  /**
   * Dead-letter logging is an operational recovery path invoked after another
   * transaction has failed. It intentionally writes in system mode so failure
   * evidence is retained even when the originating user cannot create DLQ
   * records. Callers cannot choose arbitrary fields: this service owns the
   * complete record construction.
   *
   * @param eventType The Event_Type__c of the platform event that failed to process.
   * @param payload The event payload to serialize for later inspection.
   * @param ex The exception that caused processing to fail.
   */
  @SuppressWarnings('PMD.ApexCRUDViolation')
  public static void logFailure(
    String eventType,
    Object payload,
    Exception ex
  ) {
    Event_DLQ__c record = new Event_DLQ__c();
    record.Event_Type__c = eventType;
    record.Payload__c = JSON.serialize(payload);
    record.Error_Message__c = ex.getMessage();
    record.Retry_Count__c = 0;
    record.Status__c = 'New';

    insert record;
  }

  /**
   * Redrives a single dead-lettered event: reconstructs the original
   * PartnerSync_Event__e from its stored payload and reprocesses it through
   * PartnerSyncEventHandler.reprocess() outside the trigger's per-batch
   * isolation. A successful reprocess marks the row Retried (closed, fixed
   * by retry); a repeat failure marks it Failed with the new error message.
   * Bounded by MAX_RETRY_COUNT so a permanently broken event cannot be
   * retried indefinitely.
   *
   * @param dlqId Id of the Event_DLQ__c row to retry.
   */
  public static void retry(Id dlqId) {
    PartnerAccessService.assertInternalUser();

    List<Event_DLQ__c> rows = [
      SELECT Payload__c, Retry_Count__c
      FROM Event_DLQ__c
      WHERE Id = :dlqId
      WITH SYSTEM_MODE
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Dead-lettered event not found.');
    }
    Event_DLQ__c row = rows[0];
    Integer retryCount = row.Retry_Count__c == null
      ? 0
      : Integer.valueOf(row.Retry_Count__c);
    if (retryCount >= MAX_RETRY_COUNT) {
      throw new PartnerSyncHandledException(
        'This event has reached the maximum retry count and requires manual investigation.'
      );
    }

    row.Retry_Count__c = retryCount + 1;
    row.Last_Retry_On__c = System.now();

    try {
      PartnerSync_Event__e reconstructed = (PartnerSync_Event__e) JSON.deserialize(
        row.Payload__c,
        PartnerSync_Event__e.class
      );
      PartnerSyncEventHandler.reprocess(reconstructed);
      row.Status__c = 'Retried';
      row.Error_Message__c = null;
    } catch (Exception ex) {
      row.Status__c = 'Failed';
      row.Error_Message__c = ex.getMessage();
    }

    Database.update(row, AccessLevel.SYSTEM_MODE);
  }

  /**
   * Marks a dead-lettered event Resolved without retrying it - for an
   * administrator who has investigated and determined no reprocessing is
   * needed (e.g. the event is now moot).
   *
   * @param dlqId Id of the Event_DLQ__c row to acknowledge.
   */
  public static void acknowledge(Id dlqId) {
    PartnerAccessService.assertInternalUser();

    Event_DLQ__c row = new Event_DLQ__c(Id = dlqId, Status__c = 'Resolved');
    Database.update(row, AccessLevel.SYSTEM_MODE);
  }
}
