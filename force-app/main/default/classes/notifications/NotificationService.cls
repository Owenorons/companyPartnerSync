/**
 * Write side of notification creation: turns a NotificationRequestDTO into
 * a Partner_Notification__c and fires the corresponding platform event.
 * Called internally by other domains (deals, MDF, leads, etc.) to raise a
 * notification, not called directly from the LWC layer.
 */
public with sharing class NotificationService {
  /**
   * Creates a Partner_Notification__c from the given request, inserted
   * in system mode since notifications are trusted domain side effects
   * rather than user-authored records, then logs a
   * METRIC_TYPE_NOTIFICATION_SENT usage metric and publishes the
   * corresponding platform event. Notification creation is itself a
   * side effect of some other business operation, so any exception
   * (including from the usage-metric logging) is caught and logged
   * rather than propagated, ensuring a notification failure never fails
   * the triggering operation.
   *
   * @param request The notification to create; a null request is a no-op.
   */
  public static void create(NotificationRequestDTO request) {
    if (request == null) {
      return;
    }

    // Notification creation is a side effect of some other business
    // operation (deal approval, lead assignment, etc.); a failure here must
    // never fail that operation, so every exception is caught and logged.
    try {
      Partner_Notification__c notification = new Partner_Notification__c();

      notification.Partner_Account__c = request.partnerAccountId;

      notification.Recipient_Contact__c = request.recipientContactId;

      notification.Recipient_User__c = request.recipientUserId;

      notification.Notification_Type__c = request.notificationType;

      notification.Title__c = request.title;

      notification.Message__c = request.message;

      notification.Action_Label__c = request.actionLabel;

      notification.Action_URL__c = request.actionUrl;

      notification.Related_Object__c = request.relatedObject;

      notification.Related_Record_Id__c = String.valueOf(
        request.relatedRecordId
      );

      notification.Priority__c = String.isBlank(request.priority)
        ? 'Normal'
        : request.priority;

      notification.Is_Read__c = false;

      // Notifications are trusted domain side effects, not user-authored
      // records. Their creation must not depend on recipient/actor CRUD.
      Database.insert(notification, AccessLevel.SYSTEM_MODE);

      UsageMetricService.log(
        request.partnerAccountId,
        UsageMetricService.METRIC_TYPE_NOTIFICATION_SENT
      );

      PlatformEventPublisherService.publishNotificationCreated(notification);
    } catch (Exception ex) {
      LoggingService.error(
        'NotificationService',
        'Failed to create notification.',
        ex
      );
    }
  }
}
