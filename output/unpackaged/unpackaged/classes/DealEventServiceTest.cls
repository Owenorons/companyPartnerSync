@IsTest
private class DealEventServiceTest {
  @IsTest
  static void createsDurableEventAndPendingOutboxWithoutCommandParameters() {
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Draft',
      Lifecycle_Phase__c = 'Registration'
    );
    insert deal;

    DealCommand command = new DealCommand();
    command.dealId = deal.Id;
    command.aggregateId = deal.Id;
    command.aggregateType = DealLifecycleConstants.AGGREGATE_REGISTRATION;
    command.lifecycleDimension = DealLifecycleConstants.DIMENSION_REGISTRATION;
    command.commandType = 'Submit';
    command.commandKey = 'event-service-test';
    command.correlationId = 'correlation-test';
    command.source = 'Apex';
    command.parameters.put('internalSecret', 'must-not-be-serialised');

    DealTransitionDefinition transition = new DealTransitionDefinition();
    transition.partnerVisible = true;

    DealCommandContext context = new DealCommandContext();
    context.deal = deal;
    context.command = command;
    context.transition = transition;
    context.previousState = 'Draft';
    context.newState = 'Submitted';
    context.newVersion = 1;
    context.eventType = 'DealSubmitted';

    DealEventService.EventCreationResult result = DealEventService.createEvent(
      context
    );

    Deal_Event__c eventRecord = [
      SELECT Event_Type__c, Payload__c, Partner_Visible__c
      FROM Deal_Event__c
      WHERE Id = :result.eventRecord.Id
    ];
    Deal_Event_Outbox__c outbox = [
      SELECT Status__c, Attempt_Count__c
      FROM Deal_Event_Outbox__c
      WHERE Id = :result.outboxRecord.Id
    ];

    Assert.areEqual('DealSubmitted', eventRecord.Event_Type__c);
    Assert.isTrue(eventRecord.Partner_Visible__c);
    Assert.isFalse(eventRecord.Payload__c.contains('internalSecret'));
    Assert.areEqual('Pending', outbox.Status__c);
    Assert.areEqual(0, outbox.Attempt_Count__c);
  }
}
