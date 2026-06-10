public with sharing class NotificationQueryService {
  public static List<PartnerNotificationDTO> getMyNotifications() {
    Id userId = UserInfo.getUserId();

    List<PartnerNotificationDTO> results = new List<PartnerNotificationDTO>();

    for (Partner_Notification__c row : [
      SELECT
        Id,
        Title__c,
        Message__c,
        Action_Label__c,
        Action_URL__c,
        Priority__c,
        Is_Read__c,
        CreatedDate
      FROM Partner_Notification__c
      WHERE Recipient_User__c = :userId AND Dismissed__c = FALSE
      ORDER BY CreatedDate DESC
      LIMIT 100
    ]) {
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
    return [
      SELECT COUNT()
      FROM Partner_Notification__c
      WHERE
        Recipient_User__c = :UserInfo.getUserId()
        AND Is_Read__c = FALSE
        AND Dismissed__c = FALSE
    ];
  }
}
