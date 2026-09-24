/**
 * Third of the consumers PartnerSyncEventHandler dispatches a
 * PartnerSync_Event__e to (see AuditEventConsumerService and
 * NotificationEventConsumerService for the other two). Matches the event
 * against active Webhook_Endpoint__mdt rows and enqueues delivery; unlike
 * the other two consumers, the actual callout is async
 * (WebhookDispatchQueueable) so a webhook endpoint being down never fails
 * the platform event itself or lands it in the DLQ.
 */
public with sharing class WebhookDispatchConsumerService {
  @TestVisible
  private static List<Webhook_Endpoint__mdt> testEndpoints;

  /**
   * Enqueues delivery of the given event to every active, matching
   * webhook endpoint. A no-op if nothing matches, or if the transaction is
   * already at its queueable-job limit (logged rather than thrown, since a
   * skipped webhook delivery shouldn't fail the business event itself).
   *
   * @param eventRecord The published platform event to dispatch to webhooks.
   */
  public static void dispatchBusinessEvent(PartnerSync_Event__e eventRecord) {
    if (!TenantConfigService.isWebhooksEnabled()) {
      return;
    }

    List<WebhookDispatchQueueable.Delivery> deliveries = matchingDeliveries(
      eventRecord
    );
    if (deliveries.isEmpty()) {
      return;
    }
    if (Limits.getQueueableJobs() >= Limits.getLimitQueueableJobs()) {
      LoggingService.warn(
        'WebhookDispatchConsumerService',
        'Queueable job limit reached; skipped webhook dispatch for event ' +
        eventRecord.Event_Type__c
      );
      return;
    }
    System.enqueueJob(new WebhookDispatchQueueable(deliveries));
  }

  private static List<WebhookDispatchQueueable.Delivery> matchingDeliveries(
    PartnerSync_Event__e eventRecord
  ) {
    List<WebhookDispatchQueueable.Delivery> results = new List<WebhookDispatchQueueable.Delivery>();
    String payload = buildPayload(eventRecord);

    List<Webhook_Endpoint__mdt> endpoints = Test.isRunningTest() &&
      testEndpoints != null
      ? testEndpoints
      : [
          SELECT
            DeveloperName,
            URL__c,
            Event_Filter__c,
            Retry_Count__c,
            Timeout_Seconds__c
          FROM Webhook_Endpoint__mdt
          WHERE Active__c = TRUE
          WITH SYSTEM_MODE
        ];

    for (Webhook_Endpoint__mdt endpoint : endpoints) {
      if (
        String.isBlank(endpoint.URL__c) ||
        !matchesFilter(endpoint.Event_Filter__c, eventRecord.Event_Type__c)
      ) {
        continue;
      }

      WebhookDispatchQueueable.Delivery delivery = new WebhookDispatchQueueable.Delivery();
      delivery.endpointDeveloperName = endpoint.DeveloperName;
      delivery.url = endpoint.URL__c;
      delivery.timeoutSeconds = endpoint.Timeout_Seconds__c == null
        ? 30
        : Integer.valueOf(endpoint.Timeout_Seconds__c);
      delivery.maxRetries = endpoint.Retry_Count__c == null
        ? 0
        : Integer.valueOf(endpoint.Retry_Count__c);
      delivery.attemptNumber = 1;
      delivery.eventType = eventRecord.Event_Type__c;
      delivery.payload = payload;
      results.add(delivery);
    }

    return results;
  }

  private static Boolean matchesFilter(String eventFilter, String eventType) {
    if (String.isBlank(eventFilter)) {
      return false;
    }

    for (String candidate : eventFilter.split(';')) {
      String trimmed = candidate.trim();
      if (trimmed == 'All' || trimmed == eventType) {
        return true;
      }
    }

    return false;
  }

  private static String buildPayload(PartnerSync_Event__e eventRecord) {
    return JSON.serialize(
      new Map<String, Object>{
        'eventType' => eventRecord.Event_Type__c,
        'eventId' => eventRecord.Event_Id__c,
        'occurredOn' => eventRecord.Occurred_On__c,
        'objectName' => eventRecord.Object_Name__c,
        'recordId' => eventRecord.Record_Id__c,
        'partnerAccountId' => eventRecord.Partner_Account_Id__c,
        'summary' => eventRecord.Summary__c,
        'correlationId' => eventRecord.Correlation_Id__c
      }
    );
  }
}
