/*
 * Write side of notification creation: turns a NotificationRequestDTO into
 * a Partner_Notification__c and fires the corresponding platform event.
 * Called internally by other domains (deals, MDF, leads, etc.) to raise a
 * notification, not called directly from the LWC layer.
 */
public with sharing class NotificationService {
  public static void create(NotificationRequestDTO request) {
    if (request == null) {
      return;
    }

    // Notification creation is a side effect of some other business
    // operation (deal approval, lead assignment, etc.); a failure here must
    // never fail that operation, so every exception is caught and logged.
    try {
      SecurityUtil.assertCreateable(Partner_Notification__c.SObjectType);

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

      List<SObject> sanitized = SecurityUtil.stripForCreate(
        new List<SObject>{ notification }
      );

      Database.insert(sanitized, AccessLevel.USER_MODE);

      PlatformEventPublisherService.publishNotificationCreated(
        (Partner_Notification__c) sanitized[0]
      );
    } catch (Exception ex) {
      LoggingService.error(
        'NotificationService',
        'Failed to create notification.',
        ex
      );
    }
  }
}
