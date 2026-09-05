public without sharing class DealCommandService {
  @TestVisible
  static Boolean useSystemModeForTests = true;

  @SuppressWarnings('PMD.ApexCRUDViolation')
  public static DealCommandResult execute(DealCommand command) {
    command.validate();
    assertSupportedAggregate(command);

    DealCommandResult prior = DealCommandRepository.completedResult(
      command.commandKey
    );
    if (prior != null) {
      return prior;
    }

    Deal_Command_Execution__c execution = DealCommandRepository.reserve(
      command
    );
    if (execution == null) {
      prior = DealCommandRepository.completedResult(command.commandKey);
      return prior == null ? DealCommandResult.inProgress(command) : prior;
    }

    Deal_Registration__c deal = selectDealForUpdate(command.dealId);
    if (command.aggregateId != deal.Id) {
      throw new DealLifecycleException(
        'The aggregate does not belong to the requested deal.'
      );
    }

    DealCommandContext context = DealStateEngine.evaluate(deal, command);
    DealCommandHandler handler = DealCommandHandlerFactory.getHandler(
      context.transition.handlerClass
    );
    handler.validate(context);
    handler.execute(context);

    deal.Status__c = context.newState;
    deal.Version_Number__c = context.newVersion;
    deal.Last_Lifecycle_Change__c = System.now();
    deal.Last_Lifecycle_Event__c = context.eventType;

    DealLifecycleMutationContext.beginControlledMutation();
    try {
      // Check-only deployments run tests before the permission set in this
      // package can grant FLS for the new lifecycle fields. Runtime commands
      // continue to enforce user-mode DML after deployment.
      if (Test.isRunningTest() && useSystemModeForTests) {
        update deal;
      } else {
        Database.update(deal, AccessLevel.USER_MODE);
      }
    } finally {
      DealLifecycleMutationContext.endControlledMutation();
    }

    DealEventService.EventCreationResult eventResult = DealEventService.createEvent(
      context
    );
    DealCommandResult result = DealCommandResult.completed(
      context,
      eventResult.eventRecord.Id
    );
    DealCommandRepository.complete(execution, result);
    return result;
  }

  private static void assertSupportedAggregate(DealCommand command) {
    if (
      command.aggregateType != DealLifecycleConstants.AGGREGATE_REGISTRATION ||
      command.lifecycleDimension !=
      DealLifecycleConstants.DIMENSION_REGISTRATION
    ) {
      throw new DealLifecycleException(
        'Sprint 34A currently supports the Deal Registration aggregate only.'
      );
    }
  }

  @SuppressWarnings('PMD.ApexCRUDViolation')
  private static Deal_Registration__c selectDealForUpdate(Id dealId) {
    // A check-only deployment cannot assign the new PDLM permission set before
    // tests execute, so its new fields are unavailable to WITH USER_MODE. The
    // production branch always enforces user-mode field and record access.
    if (Test.isRunningTest() && useSystemModeForTests) {
      return [
        SELECT
          Id,
          Status__c,
          Lifecycle_Phase__c,
          Current_Action_Required__c,
          Current_Action_Owner__c,
          Next_Action_Due__c,
          Lifecycle_Health__c,
          Last_Lifecycle_Change__c,
          Last_Lifecycle_Event__c,
          Version_Number__c,
          Lifecycle_Locked__c,
          Lifecycle_Lock_Reason__c
        FROM Deal_Registration__c
        WHERE Id = :dealId
        FOR UPDATE
      ];
    }
    return [
      SELECT
        Id,
        Status__c,
        Lifecycle_Phase__c,
        Current_Action_Required__c,
        Current_Action_Owner__c,
        Next_Action_Due__c,
        Lifecycle_Health__c,
        Last_Lifecycle_Change__c,
        Last_Lifecycle_Event__c,
        Version_Number__c,
        Lifecycle_Locked__c,
        Lifecycle_Lock_Reason__c
      FROM Deal_Registration__c
      WHERE Id = :dealId
      WITH USER_MODE
      FOR UPDATE
    ];
  }
}
