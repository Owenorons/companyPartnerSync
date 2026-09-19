/**
 * Aura controller surface for the in-app Partner_Notification__c bell/list
 * UI. Pure pass-through to NotificationQueryService/NotificationUpdateService
 * — no business logic here.
 */
public with sharing class NotificationController {
  /**
   * Returns the running user's active in-app notifications.
   *
   * @return List of the caller's active notifications.
   */
  @AuraEnabled(cacheable=true)
  public static List<PartnerNotificationDTO> getMyNotifications() {
    return NotificationQueryService.getMyNotifications();
  }

  /**
   * Returns the running user's count of unread, non-dismissed
   * notifications.
   *
   * @return The unread notification count.
   */
  @AuraEnabled(cacheable=true)
  public static Integer getUnreadCount() {
    return NotificationQueryService.getUnreadCount();
  }

  /**
   * Marks a notification as read for the running user.
   *
   * @param notificationId Id of the Partner_Notification__c record to mark read.
   */
  @AuraEnabled
  public static void markAsRead(Id notificationId) {
    NotificationUpdateService.markAsRead(notificationId);
  }

  /**
   * Dismisses a notification for the running user.
   *
   * @param notificationId Id of the Partner_Notification__c record to dismiss.
   */
  @AuraEnabled
  public static void dismiss(Id notificationId) {
    NotificationUpdateService.dismiss(notificationId);
  }

  /**
   * Returns the running user's Id.
   *
   * @return The current user's Id.
   */
  @AuraEnabled(cacheable=true)
  public static Id getCurrentUserId() {
    return UserInfo.getUserId();
  }
}
