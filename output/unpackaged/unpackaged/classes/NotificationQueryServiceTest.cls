/*
 * Covers NotificationQueryService's filtering rules: dismissed and
 * other-users' notifications must never surface in getMyNotifications() or
 * getUnreadCount(), and read notifications must not count as unread.
 */
@IsTest
private class NotificationQueryServiceTest {
  @IsTest
  static void getMyNotificationsExcludesDismissedAndOthersNotifications() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);
    User otherUser = TestUserFactory.createInternalUser();

    // Owned by someone else entirely — never visible to partnerUser, so it
    // can be inserted in the admin test-run context.
    insert new Partner_Notification__c(
      Partner_Account__c = partner.Id,
      Recipient_User__c = otherUser.Id,
      Title__c = 'Someone else\'s notification',
      Message__c = 'Should be excluded.',
      Is_Read__c = false,
      Dismissed__c = false
    );

    System.runAs(partnerUser) {
      // Inserted as partnerUser (not the admin test-run context) so
      // partnerUser is the record owner and can read it back regardless of
      // whether this org's partner Sharing Set has been configured yet —
      // see docs/post-install-sharing-setup.md.
      insert new List<Partner_Notification__c>{
        new Partner_Notification__c(
          Partner_Account__c = partner.Id,
          Recipient_User__c = partnerUser.Id,
          Title__c = 'Active notification',
          Message__c = 'Still relevant.',
          Is_Read__c = false,
          Dismissed__c = false
        ),
        new Partner_Notification__c(
          Partner_Account__c = partner.Id,
          Recipient_User__c = partnerUser.Id,
          Title__c = 'Dismissed notification',
          Message__c = 'Should be excluded.',
          Is_Read__c = false,
          Dismissed__c = true
        )
      };

      List<PartnerNotificationDTO> notifications = NotificationQueryService.getMyNotifications();

      System.assertEquals(
        1,
        notifications.size(),
        'Only the active notification addressed to this user should be returned.'
      );
      System.assertEquals('Active notification', notifications[0].title);

      System.assertEquals(
        1,
        NotificationQueryService.getUnreadCount(),
        'Unread count should exclude dismissed and other-user notifications.'
      );
    }
  }

  @IsTest
  static void getUnreadCountExcludesReadNotifications() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    System.runAs(partnerUser) {
      insert new Partner_Notification__c(
        Partner_Account__c = partner.Id,
        Recipient_User__c = partnerUser.Id,
        Title__c = 'Already read',
        Message__c = 'Read already.',
        Is_Read__c = true,
        Dismissed__c = false
      );

      System.assertEquals(0, NotificationQueryService.getUnreadCount());
    }
  }
}
