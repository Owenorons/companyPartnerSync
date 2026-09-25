/**
 * Orchestrates execution of a Deal Registration lifecycle command: validates
 * the command, enforces idempotency via command reservation, transitions the
 * deal through the state engine, delegates to the resolved command handler,
 * persists the resulting deal state, and emits the lifecycle event.
 */
public without sharing class DealCommandService {
  @TestVisible
  static Boolean useSystemModeForTests = true;
  @TestVisible
  private static Boolean simulateCompletionFailure = false;

  /**
   * Executes the given deal lifecycle command end to end, returning the
   * prior result unchanged if the same command key has already completed or
   * is in progress.
   *
   * @param command The deal lifecycle command to execute.
   * @return The result of executing the command.
   */
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

    // Reserving, the handler's own writes, the deal update, the event/
    // outbox insert, and completing the reservation are five-plus separate
    // DML statements. An uncaught exception here only auto-rolls-back the
    // whole transaction if it's left uncaught all the way to the
    // transaction boundary — a caller that catches and continues (e.g. a
    // batch processing many commands, matching the isolate-and-continue
    // pattern used elsewhere in this codebase) would otherwise leave a
    // stuck 'in progress' reservation behind: reserve() treats an existing
    // uncompleted reservation as a duplicate in-flight command and refuses
    // to reserve again, so a stuck reservation would permanently block
    // every future retry of that command key.
    Savepoint sp = Database.setSavepoint();
    try {
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

      if (
        context.command.commandType ==
        DealRegistrationLifecycleConstants.FINALISE_APPROVAL
      ) {
        activateProtection(deal.Id, context.newState);
        createOriginatingParticipant(deal.Id, context.newState);
      }

      DealEventService.EventCreationResult eventResult = DealEventService.createEvent(
        context
      );
      DealCommandResult result = DealCommandResult.completed(
        context,
        eventResult.eventRecord.Id
      );
      if (Test.isRunningTest() && simulateCompletionFailure) {
        throw new DealLifecycleException('Simulated completion failure.');
      }
      DealCommandRepository.complete(execution, result);
      return result;
    } catch (Exception ex) {
      Database.rollback(sp);
      throw ex;
    } finally {
      Database.releaseSavepoint(sp);
    }
  }

  // Runs after the deal's Status__c update above has committed within this
  // transaction, so DealProtectionCommandService's own fresh FOR UPDATE
  // re-query of the deal sees the just-approved status rather than the
  // pre-approval one. A blocking Protection-Blocking condition or missing
  // policy is a legitimate, expected outcome (Sprint 37's "Pending
  // Conditions" state) rather than a finalisation failure, so it's logged
  // and swallowed here instead of failing the whole approval transaction.
  private static void activateProtection(Id dealId, String newState) {
    if (newState != 'Approved' && newState != 'Approved with Conditions') {
      return;
    }
    try {
      DealProtectionCommand command = new DealProtectionCommand();
      command.dealId = dealId;
      command.action = 'Activate Protection';
      command.commandKey = 'auto-activate-' + dealId;
      DealProtectionCommandService.execute(command);
    } catch (DealProtectionCommandService.ProtectionCommandException ex) {
      LoggingService.warn(
        'DealCommandService',
        'Protection activation deferred for deal ' +
          dealId +
          ': ' +
          ex.getMessage()
      );
    }
  }

  // Backfills the originating partner as a Deal_Participant__c (Sprint 38
  // §38.9) alongside protection activation - same graceful-defer shape,
  // since a missing/duplicate backfill should defer rather than block
  // finalisation. Deal_Registration__c.Partner_Account__c remains the
  // backward-compatible projection; this is purely additive.
  private static void createOriginatingParticipant(Id dealId, String newState) {
    if (newState != 'Approved' && newState != 'Approved with Conditions') {
      return;
    }
    try {
      List<Deal_Registration__c> deals = [
        SELECT Id, Partner_Account__c
        FROM Deal_Registration__c
        WHERE Id = :dealId
        WITH SYSTEM_MODE
      ];
      if (deals.isEmpty() || deals[0].Partner_Account__c == null) {
        return;
      }

      Integer existingOriginatingParticipants = [
        SELECT COUNT()
        FROM Deal_Participant__c
        WHERE Deal__c = :dealId AND Participant_Type__c = 'Originating Partner'
        WITH SYSTEM_MODE
      ];
      if (existingOriginatingParticipants > 0) {
        return;
      }

      Datetime now = System.now();
      Database.insert(
        new Deal_Participant__c(
          Deal__c = dealId,
          Partner_Account__c = deals[0].Partner_Account__c,
          Participant_Type__c = 'Originating Partner',
          Participant_Role__c = 'Deal Owner',
          Status__c = 'Active',
          Access_Level__c = 'Full Partner',
          Effective_From__c = now,
          Last_Activity_On__c = now,
          Version_Number__c = 0
        ),
        AccessLevel.SYSTEM_MODE
      );
    } catch (Exception ex) {
      LoggingService.warn(
        'DealCommandService',
        'Originating participant backfill deferred for deal ' +
          dealId +
          ': ' +
          ex.getMessage()
      );
    }
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
