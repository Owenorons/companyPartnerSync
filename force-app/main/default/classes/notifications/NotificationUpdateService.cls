public with sharing class NotificationUpdateService {
  public static void markAsRead(Id notificationId) {
    PartnerRecordAccessService
      .assertPartnerAccessToNotification(notificationId);

    Partner_Notification__c notification = [
      SELECT Id, Is_Read__c
      FROM Partner_Notification__c
      WHERE Id = :notificationId
      LIMIT 1
    ];

    notification.Is_Read__c = true;
    notification.Read_On__c = System.now();

    update notification;
  }

  public static void dismiss(Id notificationId) {
    PartnerRecordAccessService
      .assertPartnerAccessToNotification(notificationId);

    Partner_Notification__c notification = [
      SELECT Id, Dismissed__c
      FROM Partner_Notification__c
      WHERE Id = :notificationId
      LIMIT 1
    ];

    notification.Dismissed__c = true;

    update notification;
  }
}
