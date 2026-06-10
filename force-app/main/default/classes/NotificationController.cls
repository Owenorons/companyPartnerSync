public with sharing class NotificationController {
  @AuraEnabled(cacheable=true)
  public static List<PartnerNotificationDTO> getMyNotifications() {
    return NotificationQueryService.getMyNotifications();
  }

  @AuraEnabled(cacheable=true)
  public static Integer getUnreadCount() {
    return NotificationQueryService.getUnreadCount();
  }

  @AuraEnabled
  public static void markAsRead(Id notificationId) {
    NotificationUpdateService.markAsRead(notificationId);
  }

  @AuraEnabled
  public static void dismiss(Id notificationId) {
    NotificationUpdateService.dismiss(notificationId);
  }
}
