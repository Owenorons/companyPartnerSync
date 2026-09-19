/*
 * End-to-end coverage of the event fan-out: publishes a real
 * PartnerSync_Event__e and asserts on the Audit_Log__c / Partner_Notification__c
 * side effects, rather than unit-testing the consumers directly, since the
 * whole point of this package is the trigger -> handler -> consumers wiring.
 */
@IsTest
private class PartnerSyncEventHandlerTest {
  @IsTest
  static void dealSubmittedEventCreatesAuditLogAndNotification() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Event Partner'
    );
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    PartnerSync_Event__e eventRecord = new PartnerSync_Event__e(
      Event_Type__c = 'DealSubmitted',
      Record_Id__c = null,
      Object_Name__c = 'Deal_Registration__c',
      Partner_Account_Id__c = partner.Id,
      Summary__c = 'Deal registration submitted for review.',
      Severity__c = 'Info',
      Occurred_On__c = System.now()
    );

    // Platform event subscribers normally run async after commit; wrapping
    // the publish in Test.startTest()/stopTest() forces the trigger to run
    // synchronously before stopTest() returns, so the side effects below
    // can be asserted immediately.
    Test.startTest();
    EventBus.publish(eventRecord);
    Test.stopTest();

    List<Audit_Log__c> logs = [
      SELECT Id, Action__c, Partner_Account__c
      FROM Audit_Log__c
      WHERE Partner_Account__c = :partner.Id
    ];

    System.assertEquals(
      1,
      logs.size(),
      'One audit log should be created for the event.'
    );
    System.assertEquals('Submit', logs[0].Action__c);

    List<Partner_Notification__c> notifications = [
      SELECT Id, Notification_Type__c, Title__c, Recipient_User__c
      FROM Partner_Notification__c
      WHERE Partner_Account__c = :partner.Id
    ];

    System.assertEquals(
      1,
      notifications.size(),
      'One notification should be created for the event.'
    );
    System.assertEquals('Deal Submitted', notifications[0].Title__c);
    System.assertEquals(partnerUser.Id, notifications[0].Recipient_User__c);
  }

  @IsTest
  static void unmappedEventTypeIsIgnoredByConsumers() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Event Partner'
    );
    insert partner;

    PartnerSync_Event__e eventRecord = new PartnerSync_Event__e(
      Event_Type__c = 'SomeUnrelatedEvent',
      Object_Name__c = 'Deal_Registration__c',
      Partner_Account_Id__c = partner.Id,
      Summary__c = 'Not handled by any consumer.',
      Severity__c = 'Info',
      Occurred_On__c = System.now()
    );

    Test.startTest();
    EventBus.publish(eventRecord);
    Test.stopTest();

    System.assertEquals(
      0,
      [SELECT COUNT() FROM Audit_Log__c WHERE Partner_Account__c = :partner.Id],
      'Unmapped event types should not create an audit log.'
    );
    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM Partner_Notification__c
        WHERE Partner_Account__c = :partner.Id
      ],
      'Unmapped event types should not create a notification.'
    );
  }

  @IsTest
  static void mappedEventWithoutRecipientIsDeadLetteredNotOrphaned() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'No Active Recipient Partner'
    );
    insert partner;

    Test.startTest();
    EventBus.publish(
      new PartnerSync_Event__e(
        Event_Type__c = 'DealApproved',
        Partner_Account_Id__c = partner.Id,
        Object_Name__c = 'Deal_Registration__c'
      )
    );
    Test.stopTest();

    System.assertEquals(
      0,
      [SELECT COUNT() FROM Partner_Notification__c],
      'A mapped event must never create an unaddressed notification.'
    );
    Event_DLQ__c deadLetter = [
      SELECT Status__c, Error_Message__c
      FROM Event_DLQ__c
      WHERE Event_Type__c = 'DealApproved'
      LIMIT 1
    ];
    System.assertEquals('New', deadLetter.Status__c);
    System.assert(
      deadLetter.Error_Message__c.contains('No active partner user')
    );
  }

  @IsTest
  static void eventDLQServiceLogsFailure() {
    Test.startTest();
    EventDLQService.logFailure(
      'DealSubmitted',
      new Map<String, String>{ 'DealId' => '001000000000000' },
      new PartnerSyncHandledException('Simulated failure.')
    );
    Test.stopTest();

    List<Event_DLQ__c> rows = [
      SELECT Id, Event_Type__c, Status__c, Error_Message__c
      FROM Event_DLQ__c
    ];

    System.assertEquals(1, rows.size());
    System.assertEquals('DealSubmitted', rows[0].Event_Type__c);
    System.assertEquals('New', rows[0].Status__c);
    System.assertEquals('Simulated failure.', rows[0].Error_Message__c);
  }
}
