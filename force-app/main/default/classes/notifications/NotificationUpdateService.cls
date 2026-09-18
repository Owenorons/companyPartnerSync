/**
 * Write side of the in-app notification pipeline: mark-as-read and dismiss.
 * Both actions re-check partner access to the specific notification (not
 * just object-level FLS) before mutating it — see
 * PartnerRecordAccessService.assertPartnerAccessToNotification.
 */
public with sharing class NotificationUpdateService {
  /**
   * Marks a notification as read, after verifying the running user has
   * partner access to it.
   *
   * @param notificationId Id of the Partner_Notification__c record to mark read.
   */
  public static void markAsRead(Id notificationId) {
    SecurityUtil.assertUpdateable(Partner_Notification__c.SObjectType);

    PartnerRecordAccessService.assertPartnerAccessToNotification(
      notificationId
    );

    Partner_Notification__c notification = NotificationSelector.selectForReadUpdate(
      notificationId
    );

    notification.Is_Read__c = true;
    notification.Read_On__c = System.now();

    update SecurityUtil.stripForUpdate(new List<SObject>{ notification });
  }

  /**
   * Dismisses a notification, after verifying the running user has
   * partner access to it.
   *
   * @param notificationId Id of the Partner_Notification__c record to dismiss.
   */
  public static void dismiss(Id notificationId) {
    SecurityUtil.assertUpdateable(Partner_Notification__c.SObjectType);

    PartnerRecordAccessService.assertPartnerAccessToNotification(
      notificationId
    );

    Partner_Notification__c notification = NotificationSelector.selectForDismissUpdate(
      notificationId
    );

    notification.Dismissed__c = true;

    update SecurityUtil.stripForUpdate(new List<SObject>{ notification });
  }
}
