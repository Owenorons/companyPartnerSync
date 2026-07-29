/*
 * Covers NotificationUpdateService: the owning partner can mark-as-read and
 * dismiss their own notification, and one partner cannot update another
 * partner's notification (assertPartnerAccessToNotification enforcement).
 */
@IsTest
private class NotificationUpdateServiceTest {
  @IsTest
  static void ownerCanMarkAsReadAndDismiss() {
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

      NotificationUpdateService.markAsRead(notificationId);
    }

    Partner_Notification__c afterRead = [
      SELECT Is_Read__c, Read_On__c, Dismissed__c
      FROM Partner_Notification__c
      WHERE Id = :notificationId
    ];

    System.assertEquals(true, afterRead.Is_Read__c);
    System.assertNotEquals(null, afterRead.Read_On__c);
    System.assertEquals(false, afterRead.Dismissed__c);

    System.runAs(partnerUser) {
      NotificationUpdateService.dismiss(notificationId);
    }

    Partner_Notification__c afterDismiss = [
      SELECT Dismissed__c
      FROM Partner_Notification__c
      WHERE Id = :notificationId
    ];

    System.assertEquals(true, afterDismiss.Dismissed__c);
  }

  @IsTest
  static void partnerCannotUpdateAnotherPartnersNotification() {
    Account partnerA = PartnerSyncTestDataFactory.partnerAccount('Partner A');
    insert partnerA;

    Account partnerB = PartnerSyncTestDataFactory.partnerAccount('Partner B');
    insert partnerB;

    Contact contactA = PartnerSyncTestDataFactory.partnerContact(partnerA.Id);
    insert contactA;

    Contact contactB = PartnerSyncTestDataFactory.partnerContact(partnerB.Id);
    insert contactB;

    User partnerUserA = TestUserFactory.createExternalUser(contactA.Id);
    User partnerUserB = TestUserFactory.createExternalUser(contactB.Id);

    Id notificationForAId;

    System.runAs(partnerUserA) {
      Partner_Notification__c notificationForA = new Partner_Notification__c(
        Partner_Account__c = partnerA.Id,
        Recipient_User__c = partnerUserA.Id,
        Title__c = 'Deal approved',
        Message__c = 'Your deal registration was approved.',
        Is_Read__c = false,
        Dismissed__c = false
      );
      insert notificationForA;
      notificationForAId = notificationForA.Id;
    }

    System.runAs(partnerUserB) {
      Boolean threw = false;

      try {
        NotificationUpdateService.markAsRead(notificationForAId);
      } catch (PartnerSyncHandledException ex) {
        threw = true;
      }

      System.assertEquals(
        true,
        threw,
        'Partner B should not be able to mark Partner A\'s notification as read.'
      );
    }
  }
}
