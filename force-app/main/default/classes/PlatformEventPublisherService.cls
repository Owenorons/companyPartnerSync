/**
 * Publishes the two platform event types used for cross-cutting concerns:
 * the generic PartnerSync_Event__e (audit + notification fan-out, consumed
 * by PartnerSyncEventHandler) and the more specific NotificationCreatedEvent__e
 * (drives real-time UI push once a Partner_Notification__c row exists).
 * Callers pass already-validated/insertable data; this service does not
 * enforce FLS/CRUD itself since publish() targets an event bus, not a
 * queryable/updatable record.
 */
public with sharing class PlatformEventPublisherService {
  private static final String EVENT_VERSION = '2.0';

  /**
   * Publishes a PartnerSync_Event__e for a business event, then records the
   * EventBus acceptance result via EventPublicationService. Any failure
   * (including from EventBus.publish itself) is caught and logged rather
   * than propagated, since this event only drives audit logging and
   * in-app notifications and must never roll back or surface an error on
   * the caller's primary business transaction.
   *
   * @param eventType The business event type (e.g. DealSubmitted, LeadAccepted).
   * @param recordId The Id of the record the event relates to, if any.
   * @param objectName The name of the SObject the event relates to.
   * @param partnerAccountId The Id of the partner account the event relates to, if any.
   * @param summary A short human-readable summary of the event.
   * @param severity The event severity; defaults to 'Info' when blank.
   */
  public static void publish(
    String eventType,
    Id recordId,
    String objectName,
    Id partnerAccountId,
    String summary,
    String severity
  ) {
    try {
      String eventId = newEventId();
      Datetime occurredOn = System.now();
      PartnerSync_Event__e eventRecord = new PartnerSync_Event__e();
      eventRecord.Event_Type__c = eventType;
      eventRecord.Record_Id__c = recordId == null
        ? null
        : String.valueOf(recordId);
      eventRecord.Object_Name__c = objectName;
      eventRecord.Partner_Account_Id__c = partnerAccountId == null
        ? null
        : String.valueOf(partnerAccountId);
      eventRecord.Summary__c = summary;
      eventRecord.Severity__c = String.isBlank(severity) ? 'Info' : severity;
      eventRecord.Occurred_On__c = occurredOn;
      eventRecord.Event_Id__c = eventId;
      eventRecord.Event_Version__c = EVENT_VERSION;
      eventRecord.Correlation_Id__c = eventId;
      eventRecord.Idempotency_Key__c = String.join(
        new List<String>{ eventType, String.valueOf(recordId), eventId },
        ':'
      );

      Database.SaveResult result = EventBus.publish(eventRecord);
      EventPublicationService.record(
        'PartnerSync_Event__e',
        eventType,
        eventId,
        EVENT_VERSION,
        eventRecord.Correlation_Id__c,
        eventRecord.Idempotency_Key__c,
        result
      );
    } catch (Exception ex) {
      // Swallowed intentionally: this event only drives audit logging and
      // in-app notifications, so a publish failure must never roll back or
      // surface an error on the primary business transaction that called it.
      System.debug(
        LoggingLevel.WARN,
        'Platform event publish failed: ' + ex.getMessage()
      );
    }
  }

  // Unlike publish() above, this method does not catch its own exceptions:
  // its only caller (NotificationService.create) already wraps this call in
  // a try/catch, so publish failure here is handled one level up.
  /**
   * Publishes a NotificationCreatedEvent__e for an already-inserted
   * Partner_Notification__c, to drive real-time UI push, then records the
   * EventBus acceptance result via EventPublicationService. Unlike
   * publish(), this method does not catch its own exceptions — its only
   * caller (NotificationService.create) already wraps this call in a
   * try/catch.
   *
   * @param notification The already-inserted notification record to publish an event for.
   */
  public static void publishNotificationCreated(
    Partner_Notification__c notification
  ) {
    String eventId = newEventId();
    NotificationCreatedEvent__e eventRecord = new NotificationCreatedEvent__e();

    eventRecord.NotificationId__c = String.valueOf(notification.Id);

    eventRecord.RecipientUserId__c = String.valueOf(
      notification.Recipient_User__c
    );

    eventRecord.PartnerAccountId__c = String.valueOf(
      notification.Partner_Account__c
    );

    eventRecord.Type__c = notification.Notification_Type__c;

    eventRecord.Title__c = notification.Title__c;

    eventRecord.Message__c = notification.Message__c;

    eventRecord.NavigationUrl__c = notification.Navigation_URL__c;

    eventRecord.EventVersion__c = EVENT_VERSION;
    eventRecord.EventId__c = eventId;
    eventRecord.CorrelationId__c = String.valueOf(notification.Id);
    eventRecord.IdempotencyKey__c = 'NotificationCreated:' + notification.Id;

    Database.SaveResult result = EventBus.publish(eventRecord);
    EventPublicationService.record(
      'NotificationCreatedEvent__e',
      'NotificationCreated',
      eventId,
      EVENT_VERSION,
      eventRecord.CorrelationId__c,
      eventRecord.IdempotencyKey__c,
      result
    );
  }

  private static String newEventId() {
    return EncodingUtil.convertToHex(Crypto.generateAesKey(128));
  }
}
