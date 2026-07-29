/*
 * Covers NotificationController's delegation to the query/update services
 * end-to-end (get notifications, unread count, mark read, dismiss) as the
 * record owner.
 */
@IsTest
private class NotificationControllerTest {
  @IsTest
  static void controllerDelegatesReadDismissAndCurrentUser() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    Id notificationId;

    System.runAs(partnerUser) {
      // Inserted as partnerUser so they own the record and can read/update it
      // back regardless of whether this org's partner Sharing Set has been
      // configured yet — see docs/post-install-sharing-setup.md.
      Partner_Notification__c notification = new Partner_Notification__c(
        Partner_Account__c = partner.Id,
        Recipient_User__c = partnerUser.Id,
        Title__c = 'Deal approved',
        Message__c = 'Your deal registration was approved.',
        Is_Read__c = false,
        Dismissed__c = false
      );
      insert notification;
      notificationId = notification.Id;

      System.assertEquals(
        partnerUser.Id,
        NotificationController.getCurrentUserId()
      );

      System.assertEquals(
        1,
        NotificationController.getMyNotifications().size()
      );

      System.assertEquals(1, NotificationController.getUnreadCount());

      NotificationController.markAsRead(notificationId);
      NotificationController.dismiss(notificationId);
    }

    Partner_Notification__c updated = [
      SELECT Is_Read__c, Dismissed__c
      FROM Partner_Notification__c
      WHERE Id = :notificationId
    ];

    System.assertEquals(true, updated.Is_Read__c);
    System.assertEquals(true, updated.Dismissed__c);
  }
}
