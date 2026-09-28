/**
 * Trigger handler for PartnerSyncEventTrigger (after insert on
 * PartnerSync_Event__e), fanning each event out to the audit,
 * notification, webhook-dispatch, approval-return, and customer-success
 * consumers. This is the entry point for the whole events/ package.
 */
public with sharing class PartnerSyncEventHandler {
  /**
   * Entry point invoked by PartnerSyncEventTrigger for a batch of newly
   * published PartnerSync_Event__e records. Resolves notification
   * recipients for the batch up front, then dispatches each event to the
   * audit and notification consumers, isolating and dead-lettering any
   * per-event failure so one bad event does not affect the rest of the
   * batch.
   *
   * @param events The batch of published platform events to process.
   */
  public static void handle(List<PartnerSync_Event__e> events) {
    Set<Id> partnerAccountIds = new Set<Id>();
    for (PartnerSync_Event__e eventRecord : events) {
      Id partnerAccountId = idOrNull(eventRecord.Partner_Account_Id__c);
      if (partnerAccountId != null)
        partnerAccountIds.add(partnerAccountId);
    }
    Map<Id, List<User>> recipientsByAccount = NotificationRecipientResolver.resolveByPartnerAccount(
      partnerAccountIds
    );
    for (PartnerSync_Event__e eventRecord : events) {
      try {
        process(eventRecord, recipientsByAccount);
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

  /**
   * Re-dispatches a single event outside the trigger's per-batch isolation,
   * for manual redrive from the dead-letter queue (EventDLQService.retry()).
   * Unlike handle(), failures are not caught here - the caller decides how
   * to record a repeat failure.
   *
   * @param eventRecord The event to reprocess, typically reconstructed from a dead-lettered payload.
   */
  public static void reprocess(PartnerSync_Event__e eventRecord) {
    Id partnerAccountId = idOrNull(eventRecord.Partner_Account_Id__c);
    Set<Id> partnerAccountIds = new Set<Id>();
    if (partnerAccountId != null) {
      partnerAccountIds.add(partnerAccountId);
    }
    Map<Id, List<User>> recipientsByAccount = NotificationRecipientResolver.resolveByPartnerAccount(
      partnerAccountIds
    );
    process(eventRecord, recipientsByAccount);
  }

  private static void process(
    PartnerSync_Event__e eventRecord,
    Map<Id, List<User>> recipientsByAccount
  ) {
    AuditEventConsumerService.logBusinessEvent(eventRecord);
    Id partnerAccountId = idOrNull(eventRecord.Partner_Account_Id__c);
    NotificationEventConsumerService.notifyBusinessEvent(
      eventRecord,
      recipientsByAccount.get(partnerAccountId)
    );
    WebhookDispatchConsumerService.dispatchBusinessEvent(eventRecord);
    ApprovalReturnConsumerService.handleReturnedPlan(eventRecord);
    CustomerSuccessEventConsumerService.handleBusinessEvent(eventRecord);
  }

  private static Id idOrNull(String value) {
    return String.isBlank(value) ? null : (Id) value;
  }
}
