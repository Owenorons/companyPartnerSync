/*
 * Covers EventDLQService.retry()/acknowledge(): a redriven event that
 * reprocesses successfully is marked Retried, a redriven event that fails
 * again is marked Failed with the new error, retrying past MAX_RETRY_COUNT
 * is rejected, and acknowledge() marks a row Resolved without reprocessing.
 */
@IsTest
private class EventDLQServiceTest {
  @IsTest
  static void retryingAReprocessableEventMarksItRetried() {
    User internalUser = TestUserFactory.createInternalUser();
    Event_DLQ__c dlq = insertDeadLetter(validPayload());

    System.runAs(internalUser) {
      Test.startTest();
      EventDLQService.retry(dlq.Id);
      Test.stopTest();
    }

    Event_DLQ__c reloaded = [
      SELECT Status__c, Retry_Count__c, Last_Retry_On__c, Error_Message__c
      FROM Event_DLQ__c
      WHERE Id = :dlq.Id
    ];
    Assert.areEqual('Retried', reloaded.Status__c);
    Assert.areEqual(1, reloaded.Retry_Count__c);
    Assert.isNotNull(reloaded.Last_Retry_On__c);
    Assert.isNull(reloaded.Error_Message__c);
  }

  @IsTest
  static void retryingAnUnreconstructablePayloadMarksItFailed() {
    User internalUser = TestUserFactory.createInternalUser();
    Event_DLQ__c dlq = insertDeadLetter('not valid json');

    System.runAs(internalUser) {
      EventDLQService.retry(dlq.Id);
    }

    Event_DLQ__c reloaded = [
      SELECT Status__c, Retry_Count__c, Error_Message__c
      FROM Event_DLQ__c
      WHERE Id = :dlq.Id
    ];
    Assert.areEqual('Failed', reloaded.Status__c);
    Assert.areEqual(1, reloaded.Retry_Count__c);
    Assert.isNotNull(reloaded.Error_Message__c);
  }

  @IsTest
  static void retryingPastTheMaxRetryCountIsRejected() {
    User internalUser = TestUserFactory.createInternalUser();
    Event_DLQ__c dlq = insertDeadLetter(validPayload());
    dlq.Retry_Count__c = EventDLQService.MAX_RETRY_COUNT;
    update dlq;

    System.runAs(internalUser) {
      try {
        EventDLQService.retry(dlq.Id);
        Assert.fail(
          'Expected retrying past the max retry count to be rejected.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('maximum retry count'));
      }
    }
  }

  @IsTest
  static void acknowledgeMarksTheRowResolvedWithoutReprocessing() {
    User internalUser = TestUserFactory.createInternalUser();
    Event_DLQ__c dlq = insertDeadLetter(validPayload());

    System.runAs(internalUser) {
      EventDLQService.acknowledge(dlq.Id);
    }

    Event_DLQ__c reloaded = [
      SELECT Status__c, Retry_Count__c
      FROM Event_DLQ__c
      WHERE Id = :dlq.Id
    ];
    Assert.areEqual('Resolved', reloaded.Status__c);
    Assert.areEqual(
      0,
      reloaded.Retry_Count__c,
      'Acknowledging must not count as a retry attempt.'
    );
  }

  private static Event_DLQ__c insertDeadLetter(String payload) {
    Event_DLQ__c dlq = new Event_DLQ__c(
      Event_Type__c = 'TestEventType',
      Payload__c = payload,
      Error_Message__c = 'Original failure.',
      Retry_Count__c = 0,
      Status__c = 'New'
    );
    insert dlq;
    return dlq;
  }

  private static String validPayload() {
    // ExecutiveSnapshotComputed is deliberately absent from
    // NotificationEventConsumerService's maps (it's an org-wide event with
    // no partner account for recipient resolution - see Sprint 44), so
    // reprocessing it here exercises a real, successful redrive without
    // requiring a partner-account/recipient fixture.
    return JSON.serialize(
      new Map<String, Object>{
        'Event_Type__c' => 'ExecutiveSnapshotComputed',
        'Object_Name__c' => 'Executive_Snapshot__c'
      }
    );
  }
}
