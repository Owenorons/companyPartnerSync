/*
 * Aura controller surface for the in-app Partner_Notification__c bell/list
 * UI. Pure pass-through to NotificationQueryService/NotificationUpdateService
 * — no business logic here.
 */
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

  @AuraEnabled(cacheable=true)
  public static Id getCurrentUserId() {
    return UserInfo.getUserId();
  }
}
