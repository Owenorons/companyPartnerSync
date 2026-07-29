/*
 * Covers NotificationService.create(): default priority handling, respecting
 * an explicit priority, and that a null request is swallowed rather than
 * throwing (see the try/catch in NotificationService itself).
 */
@IsTest
private class NotificationServiceTest {
  @IsTest
  static void createPersistsNotificationWithDefaults() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    NotificationRequestDTO request = new NotificationRequestDTO();
    request.partnerAccountId = partner.Id;
    request.recipientContactId = contact.Id;
    request.recipientUserId = partnerUser.Id;
    request.notificationType = 'Deal_Update';
    request.title = 'Deal approved';
    request.message = 'Your deal registration was approved.';
    request.actionLabel = 'View Deal';
    request.actionUrl = '/deals/123';
    request.relatedObject = 'Deal_Registration__c';

    Test.startTest();
    NotificationService.create(request);
    Test.stopTest();

    Partner_Notification__c inserted = [
      SELECT
        Title__c,
        Message__c,
        Priority__c,
        Is_Read__c,
        Dismissed__c,
        Notification_Type__c,
        Recipient_User__c
      FROM Partner_Notification__c
      WHERE Partner_Account__c = :partner.Id
      LIMIT 1
    ];

    System.assertEquals('Deal approved', inserted.Title__c);
    System.assertEquals(
      'Normal',
      inserted.Priority__c,
      'Priority should default to Normal when not supplied.'
    );
    System.assertEquals(false, inserted.Is_Read__c);
    System.assertEquals(partnerUser.Id, inserted.Recipient_User__c);
  }

  @IsTest
  static void createRespectsExplicitPriority() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    NotificationRequestDTO request = new NotificationRequestDTO();
    request.partnerAccountId = partner.Id;
    request.notificationType = 'MDF_Update';
    request.title = 'Budget alert';
    request.message = 'Your MDF budget is running low.';
    request.priority = 'High';

    NotificationService.create(request);

    Partner_Notification__c inserted = [
      SELECT Priority__c
      FROM Partner_Notification__c
      WHERE Partner_Account__c = :partner.Id
      LIMIT 1
    ];

    System.assertEquals('High', inserted.Priority__c);
  }

  @IsTest
  static void createSwallowsNullRequestWithoutError() {
    Boolean threw = false;

    try {
      NotificationService.create(null);
    } catch (Exception ex) {
      threw = true;
    }

    System.assertEquals(
      false,
      threw,
      'A null request should be a no-op, not an exception.'
    );

    System.assertEquals(0, [SELECT COUNT() FROM Partner_Notification__c]);
  }
}
