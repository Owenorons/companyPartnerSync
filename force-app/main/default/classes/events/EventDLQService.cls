/*
 * Dead-letter queue for platform event processing failures: when
 * PartnerSyncEventHandler catches an exception from a consumer, it lands
 * here instead of being lost, so it can be inspected/retried later.
 */
public with sharing class EventDLQService {
  /*
   * Dead-letter logging is an operational recovery path invoked after another
   * transaction has failed. It intentionally writes in system mode so failure
   * evidence is retained even when the originating user cannot create DLQ
   * records. Callers cannot choose arbitrary fields: this service owns the
   * complete record construction.
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
}
