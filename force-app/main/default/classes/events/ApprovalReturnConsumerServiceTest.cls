/*
 * End-to-end coverage of the ApprovalPlanReturned reaction: publishes a real
 * PartnerSync_Event__e and asserts on the MDF_Request__c side effect,
 * matching PartnerSyncEventHandlerTest's approach of exercising the whole
 * trigger -> handler -> consumer chain rather than unit-testing the
 * consumer in isolation.
 */
@IsTest
private class ApprovalReturnConsumerServiceTest {
  @IsTest
  static void returnedMdfPlanEventFlipsRequestToNeedsInformation() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Return Consumer Partner'
    );
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    MDF_Request__c request = PartnerSyncTestDataFactory.mdfRequest(
      partner.Id,
      contact.Id
    );
    request.Status__c = 'Under Review';
    insert request;

    Test.startTest();
    EventBus.publish(
      new PartnerSync_Event__e(
        Event_Type__c = 'ApprovalPlanReturned',
        Record_Id__c = request.Id,
        Object_Name__c = 'MDF_Request__c',
        Summary__c = 'Missing supporting documentation',
        Severity__c = 'Warning',
        Occurred_On__c = System.now()
      )
    );
    Test.stopTest();

    MDF_Request__c updated = [
      SELECT Status__c, Return_Reason__c
      FROM MDF_Request__c
      WHERE Id = :request.Id
    ];
    Assert.areEqual('Needs Information', updated.Status__c);
    Assert.areEqual(
      'Missing supporting documentation',
      updated.Return_Reason__c
    );
  }

  @IsTest
  static void returnedPlanEventForUnwiredObjectIsANoOp() {
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Under Review',
      Estimated_Revenue__c = 100000
    );
    insert deal;

    Test.startTest();
    EventBus.publish(
      new PartnerSync_Event__e(
        Event_Type__c = 'ApprovalPlanReturned',
        Record_Id__c = deal.Id,
        Object_Name__c = 'Deal_Registration__c',
        Summary__c = 'Missing supporting documentation',
        Severity__c = 'Warning',
        Occurred_On__c = System.now()
      )
    );
    Test.stopTest();

    Assert.areEqual(
      'Under Review',
      [SELECT Status__c FROM Deal_Registration__c WHERE Id = :deal.Id].Status__c
    );
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM Event_DLQ__c],
      'An object with no wired-up reaction is a deliberate no-op, not a failure.'
    );
  }
}
