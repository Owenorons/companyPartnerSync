/**
 * Selector layer for Partner_Notification__c, used by both the query side
 * (NotificationQueryService) and the update side (NotificationUpdateService).
 * selectAccessibleNotification() is the one non-CRUD query here — it scopes
 * a record to a specific partner account + user for access checks rather
 * than plain retrieval.
 */
public with sharing class NotificationSelector {
  /**
   * Returns a user's active (non-dismissed) notifications, most recent
   * first.
   *
   * @param userId Id of the recipient user.
   * @return Up to 100 active Partner_Notification__c records for that user.
   */
  public static List<Partner_Notification__c> selectMyActiveNotifications(
    Id userId
  ) {
    SecurityUtil.assertReadable(Partner_Notification__c.SObjectType);

    return [
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
      WITH USER_MODE
      ORDER BY CreatedDate DESC
      LIMIT 100
    ];
  }

  /**
   * Counts a user's unread, non-dismissed notifications.
   *
   * @param userId Id of the recipient user.
   * @return The number of unread, non-dismissed notifications for that user.
   */
  public static Integer countUnreadForUser(Id userId) {
    SecurityUtil.assertReadable(Partner_Notification__c.SObjectType);

    return [
      SELECT COUNT()
      FROM Partner_Notification__c
      WHERE
        Recipient_User__c = :userId
        AND Is_Read__c = FALSE
        AND Dismissed__c = FALSE
      WITH USER_MODE
    ];
  }

  /**
   * Returns a single notification for the mark-as-read update.
   *
   * @param notificationId Id of the Partner_Notification__c record to fetch.
   * @return The matching Partner_Notification__c record.
   */
  public static Partner_Notification__c selectForReadUpdate(Id notificationId) {
    SecurityUtil.assertReadable(Partner_Notification__c.SObjectType);

    List<Partner_Notification__c> rows = [
      SELECT Id, Is_Read__c
      FROM Partner_Notification__c
      WHERE Id = :notificationId
      WITH USER_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Notification not found.');
    }

    return rows[0];
  }

  /**
   * Returns a single notification for the dismiss update.
   *
   * @param notificationId Id of the Partner_Notification__c record to fetch.
   * @return The matching Partner_Notification__c record.
   */
  public static Partner_Notification__c selectForDismissUpdate(
    Id notificationId
  ) {
    SecurityUtil.assertReadable(Partner_Notification__c.SObjectType);

    List<Partner_Notification__c> rows = [
      SELECT Id, Dismissed__c
      FROM Partner_Notification__c
      WHERE Id = :notificationId
      WITH USER_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Notification not found.');
    }

    return rows[0];
  }

  /**
   * Returns a notification only if it belongs to the given partner
   * account and recipient user, for access-checking purposes.
   *
   * @param notificationId Id of the Partner_Notification__c record to fetch.
   * @param partnerAccountId Id of the partner account the notification must belong to.
   * @param userId Id of the user the notification must be addressed to.
   * @return The matching Partner_Notification__c record.
   */
  public static Partner_Notification__c selectAccessibleNotification(
    Id notificationId,
    Id partnerAccountId,
    Id userId
  ) {
    SecurityUtil.assertReadable(Partner_Notification__c.SObjectType);

    List<Partner_Notification__c> rows = [
      SELECT Id
      FROM Partner_Notification__c
      WHERE
        Id = :notificationId
        AND Partner_Account__c = :partnerAccountId
        AND Recipient_User__c = :userId
      WITH USER_MODE
      LIMIT 1
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Notification not accessible.');
    }

    return rows[0];
  }
}
