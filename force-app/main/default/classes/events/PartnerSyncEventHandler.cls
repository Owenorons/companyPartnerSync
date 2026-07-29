/*
 * Trigger handler for PartnerSyncEventTrigger (after insert on
 * PartnerSync_Event__e), fanning each event out to the audit and
 * notification consumers. This is the entry point for the whole
 * events/ package.
 */
public with sharing class PartnerSyncEventHandler {
  public static void handle(List<PartnerSync_Event__e> events) {
    for (PartnerSync_Event__e eventRecord : events) {
      try {
        process(eventRecord);
      } catch (Exception ex) {
        // Platform event triggers process a batch; one bad event must not
        // stop the rest of the batch from reaching the consumers, so each
        // event is isolated in its own try/catch and failures are dead-
        // lettered individually rather than bubbling up and rolling back
        // (which would also silently drop the already-published event).
        EventDLQService.logFailure(eventRecord.Event_Type__c, eventRecord, ex);
      }
    }
  }

  private static void process(PartnerSync_Event__e eventRecord) {
    AuditEventConsumerService.logBusinessEvent(eventRecord);
    NotificationEventConsumerService.notifyBusinessEvent(eventRecord);
  }
}
