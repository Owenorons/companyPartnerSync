@IsTest
private class PlatformEventPublisherServiceTest {
  @IsTest
  static void publisherAddsEnvelopeAndRecordsAcceptance() {
    Test.startTest();
    PlatformEventPublisherService.publish(
      'UnmappedReliabilityTest',
      null,
      'Account',
      null,
      'Envelope verification',
      'Info'
    );
    Test.stopTest();

    Event_Publication__c publication = [
      SELECT
        Event_Name__c,
        Event_Type__c,
        Event_Id__c,
        Event_Version__c,
        Correlation_Id__c,
        Idempotency_Key__c,
        Status__c,
        Replay_Id__c
      FROM Event_Publication__c
      WHERE Event_Type__c = 'UnmappedReliabilityTest'
      LIMIT 1
    ];
    System.assertEquals('PartnerSync_Event__e', publication.Event_Name__c);
    System.assertEquals('2.0', publication.Event_Version__c);
    System.assertEquals(publication.Event_Id__c, publication.Correlation_Id__c);
    System.assert(
      publication.Idempotency_Key__c.contains(publication.Event_Id__c)
    );
    System.assertEquals('Accepted', publication.Status__c);
    System.assertNotEquals(null, publication.Replay_Id__c);
  }

  @IsTest
  static void rejectedPublishIsRecordedAsFailed() {
    String overlongEventType = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX';

    Test.startTest();
    PlatformEventPublisherService.publish(
      overlongEventType,
      null,
      'Account',
      null,
      'Rejected publication verification',
      'Info'
    );
    Test.stopTest();

    Event_Publication__c publication = [
      SELECT Status__c, Error_Detail__c
      FROM Event_Publication__c
      WHERE Event_Type__c = :overlongEventType.substring(0, 100)
      LIMIT 1
    ];
    System.assertEquals('Failed', publication.Status__c);
    System.assertNotEquals(null, publication.Error_Detail__c);
  }

  @IsTest
  static void publicationLedgerFailureIsContainedAndLogged() {
    Database.SaveResult sourceResult = Database.insert(
      new Account(Name = 'Publication result source'),
      false
    );
    EventPublicationService.record(
      null,
      null,
      null,
      null,
      null,
      null,
      sourceResult
    );
    Assert.areEqual(0, [SELECT COUNT() FROM Event_Publication__c]);
  }
}
