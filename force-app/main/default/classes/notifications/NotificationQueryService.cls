/*
 * Read side of the in-app notification pipeline: maps a user's active
 * Partner_Notification__c records to the LWC-facing DTO and computes the
 * unread badge count. NotificationUpdateService is the write side
 * (mark-read/dismiss); NotificationService is where notifications originate.
 */
public with sharing class NotificationQueryService {
  public static List<PartnerNotificationDTO> getMyNotifications() {
    Id userId = UserInfo.getUserId();

    List<PartnerNotificationDTO> results = new List<PartnerNotificationDTO>();

    for (
      Partner_Notification__c row : NotificationSelector.selectMyActiveNotifications(
        userId
      )
    ) {
      PartnerNotificationDTO dto = new PartnerNotificationDTO();

      dto.notificationId = row.Id;
      dto.title = row.Title__c;
      dto.message = row.Message__c;
      dto.actionLabel = row.Action_Label__c;
      dto.actionUrl = row.Action_URL__c;
      dto.priority = row.Priority__c;
      dto.isRead = row.Is_Read__c;
      dto.createdDate = row.CreatedDate;

      results.add(dto);
    }

    return results;
  }

  public static Integer getUnreadCount() {
    return NotificationSelector.countUnreadForUser(UserInfo.getUserId());
  }
}
