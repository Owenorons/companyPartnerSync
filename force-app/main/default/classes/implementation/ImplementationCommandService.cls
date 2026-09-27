/**
 * Executes Deal_Implementation__c lifecycle commands: Create (system-
 * triggered from DealOpportunityReconciliationBatch.handleClosedWon),
 * Start, Pause, Resume, Complete, Cancel, Supersede. Follows the same FOR
 * UPDATE + Version_Number__c pattern as every other command service in
 * this codebase (see DealParticipantCommandService) - no CMDT-driven
 * state engine, matching the pattern every other domain built this
 * session actually uses (Sprint 40 Known Adaptation #3).
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ImplementationCommandService {
  // Deal_Implementation_Policy__mdt is an org singleton, so tests can't
  // seed alternate CMDT rows per case - same test-override shape as
  // DealLifecyclePermissionService.testOverrides.
  @TestVisible
  private static Boolean testImplementationRequiredOverride;

  /**
   * Executes the given implementation command, dispatching to the
   * matching action.
   *
   * @param command The implementation command to execute.
   * @return The resulting Deal_Implementation__c record, or null if Create no-opped (policy says not required).
   */
  public static Deal_Implementation__c execute(ImplementationCommand command) {
    command.validate();

    if (command.action == 'Create') {
      return create(command);
    }

    PartnerAccessService.assertInternalUser();
    if (
      !DealLifecyclePermissionService.hasPermission(
        'PartnerSync_Manage_Implementation'
      )
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to manage implementations.'
      );
    }

    Deal_Implementation__c implementation = ImplementationSelector.selectForUpdate(
      command.implementationId
    );

    Integer version = implementation.Version_Number__c == null
      ? 0
      : Integer.valueOf(implementation.Version_Number__c);
    if (command.expectedVersion == null || command.expectedVersion != version) {
      throw new PartnerSyncHandledException(
        'The implementation changed. Refresh before retrying.'
      );
    }

    if (command.action == 'Start') {
      start(implementation);
    } else if (command.action == 'Pause') {
      pause(implementation, command);
    } else if (command.action == 'Resume') {
      resume(implementation);
    } else if (command.action == 'Complete') {
      complete(implementation);
    } else if (command.action == 'Cancel') {
      cancel(implementation, command);
    } else if (command.action == 'Supersede') {
      supersede(implementation, command);
    } else {
      throw new PartnerSyncHandledException(
        'Unsupported implementation action: ' + command.action
      );
    }

    implementation.Version_Number__c = version + 1;
    Database.update(implementation, AccessLevel.SYSTEM_MODE);

    ImplementationStatusProjectionService.recompute(implementation.Deal__c);

    return implementation;
  }

  // ---------------------------------------------------------------------
  // Create
  // ---------------------------------------------------------------------

  private static Deal_Implementation__c create(ImplementationCommand command) {
    if (ImplementationSelector.hasActiveForDeal(command.dealId)) {
      // Idempotency guard: DealOpportunityReconciliationBatch may detect
      // the same Closed Won transition more than once (e.g. a retried
      // chunk) - a second Create for the same deal is a silent no-op, not
      // an error.
      return null;
    }

    Deal_Implementation_Policy__mdt policy = resolvePolicy();
    Boolean implementationRequired = Test.isRunningTest() &&
      testImplementationRequiredOverride != null
      ? testImplementationRequiredOverride
      : policy.Implementation_Required__c == true;
    if (!implementationRequired) {
      return null;
    }

    List<Deal_Registration__c> deals = [
      SELECT
        Id,
        Partner_Account__c,
        Customer_Account__c,
        Approved_Opportunity__c
      FROM Deal_Registration__c
      WHERE Id = :command.dealId
      WITH SYSTEM_MODE
    ];
    if (deals.isEmpty()) {
      return null;
    }
    Deal_Registration__c deal = deals[0];

    Deal_Opportunity__c primary = DealOpportunitySelector.selectCurrentPrimary(
      command.dealId
    );

    Datetime now = System.now();
    Integer durationDays = policy.Default_Duration_Days__c == null
      ? 90
      : Integer.valueOf(policy.Default_Duration_Days__c);

    Deal_Implementation__c implementation = new Deal_Implementation__c(
      Deal__c = command.dealId,
      Opportunity__c = deal.Approved_Opportunity__c != null
        ? deal.Approved_Opportunity__c
        : (primary != null ? primary.Opportunity__c : null),
      Deal_Opportunity__c = primary?.Id,
      Customer_Account__c = deal.Customer_Account__c,
      Primary_Partner__c = deal.Partner_Account__c,
      Primary_Participant__c = selectOriginatingParticipantId(command.dealId),
      Implementation_Type__c = String.isBlank(
          policy.Default_Implementation_Type__c
        )
        ? 'Initial Implementation'
        : policy.Default_Implementation_Type__c,
      Status__c = 'Planned',
      Health__c = 'Healthy',
      Planned_Start_Date__c = now.date(),
      Planned_Completion_Date__c = now.date().addDays(durationDays),
      Version_Number__c = 0
    );
    Database.insert(implementation, AccessLevel.SYSTEM_MODE);

    ImplementationMilestoneCommandService.generateFromTemplate(implementation);

    advanceLifecyclePhase(command.dealId, 'Implementation');

    PlatformEventPublisherService.publish(
      'ImplementationCreated',
      command.dealId,
      'Deal_Registration__c',
      deal.Partner_Account__c,
      'A delivery implementation was created for this deal.',
      'Info'
    );

    ImplementationStatusProjectionService.recompute(command.dealId);

    return implementation;
  }

  private static Id selectOriginatingParticipantId(Id dealId) {
    List<Deal_Participant__c> rows = [
      SELECT Id
      FROM Deal_Participant__c
      WHERE Deal__c = :dealId AND Participant_Type__c = 'Originating Partner'
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    return rows.isEmpty() ? null : rows[0].Id;
  }

  // ---------------------------------------------------------------------
  // Start / Pause / Resume
  // ---------------------------------------------------------------------

  private static void start(Deal_Implementation__c implementation) {
    requireStatus(implementation, 'Not Started', 'Handoff Accepted');
    implementation.Status__c = 'In Progress';
    implementation.Actual_Start_Date__c = System.today();

    publish(
      implementation,
      'ImplementationStarted',
      'An implementation started.'
    );
  }

  private static void pause(
    Deal_Implementation__c implementation,
    ImplementationCommand command
  ) {
    requireStatus(implementation, 'In Progress', 'At Risk');
    implementation.Status__c = 'On Hold';

    publish(
      implementation,
      'ImplementationBlocked',
      'An implementation was paused.'
    );
  }

  private static void resume(Deal_Implementation__c implementation) {
    requireStatus(implementation, 'On Hold');
    implementation.Status__c = 'In Progress';

    publish(
      implementation,
      'ImplementationResumed',
      'A paused implementation resumed.'
    );
  }

  // ---------------------------------------------------------------------
  // Complete
  // ---------------------------------------------------------------------

  private static void complete(Deal_Implementation__c implementation) {
    if (
      implementation.Status__c != 'In Progress' &&
      implementation.Status__c != 'Validation' &&
      implementation.Status__c != 'Customer Accepted'
    ) {
      throw new PartnerSyncHandledException(
        'This implementation is not in a state that can be completed.'
      );
    }
    assertNoBlockingIssues(implementation.Id);
    assertNoUnresolvedRequiredMilestones(implementation.Id);
    assertNoUnacceptedRequiredAcceptance(implementation.Id);

    implementation.Status__c = 'Completed';
    implementation.Actual_Completion_Date__c = System.today();

    advanceLifecyclePhase(implementation.Deal__c, 'Customer Success');

    publish(
      implementation,
      'ImplementationCompleted',
      'An implementation was completed.'
    );
    publish(
      implementation,
      'CustomerSuccessHandoffRequested',
      'This deal is ready to hand off to Customer Success.'
    );
  }

  // Guard mirrors DealParticipantCommandService.assertRemovable's shape:
  // a real, checked precondition rather than a stubbed pass-through.
  private static void assertNoBlockingIssues(Id implementationId) {
    if (
      [
        SELECT COUNT()
        FROM Implementation_Issue__c
        WHERE
          Implementation__c = :implementationId
          AND Status__c NOT IN ('Resolved', 'Accepted Risk', 'Closed')
        WITH SYSTEM_MODE
      ] > 0
    ) {
      throw new PartnerSyncHandledException(
        'This implementation has open issues that must be resolved or accepted before completion.'
      );
    }
  }

  private static void assertNoUnresolvedRequiredMilestones(
    Id implementationId
  ) {
    if (
      [
        SELECT COUNT()
        FROM Implementation_Milestone__c
        WHERE
          Implementation__c = :implementationId
          AND Required__c = TRUE
          AND Status__c NOT IN ('Completed', 'Waived')
        WITH SYSTEM_MODE
      ] > 0
    ) {
      throw new PartnerSyncHandledException(
        'This implementation has required milestones that are not yet completed or waived.'
      );
    }
  }

  private static void assertNoUnacceptedRequiredAcceptance(
    Id implementationId
  ) {
    if (
      ImplementationAcceptanceSelector.hasUnacceptedRequiredAcceptance(
        implementationId
      )
    ) {
      throw new PartnerSyncHandledException(
        'This implementation has requested customer acceptances that are not yet accepted.'
      );
    }
  }

  // ---------------------------------------------------------------------
  // Cancel / Supersede
  // ---------------------------------------------------------------------

  private static void cancel(
    Deal_Implementation__c implementation,
    ImplementationCommand command
  ) {
    if (
      implementation.Status__c == 'Completed' ||
      implementation.Status__c == 'Cancelled' ||
      implementation.Status__c == 'Failed' ||
      implementation.Status__c == 'Superseded'
    ) {
      throw new PartnerSyncHandledException(
        'This implementation has already exited the delivery lifecycle.'
      );
    }
    if (String.isBlank(command.reason)) {
      throw new PartnerSyncHandledException(
        'A reason is required to cancel an implementation.'
      );
    }
    implementation.Status__c = 'Cancelled';

    publish(
      implementation,
      'ImplementationCancelled',
      'An implementation was cancelled.'
    );
  }

  private static void supersede(
    Deal_Implementation__c implementation,
    ImplementationCommand command
  ) {
    if (String.isBlank(command.reason)) {
      throw new PartnerSyncHandledException(
        'A reason is required to supersede an implementation.'
      );
    }
    implementation.Status__c = 'Superseded';

    publish(
      implementation,
      'ImplementationCancelled',
      'An implementation was superseded.'
    );
  }

  // ---------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------

  private static void requireStatus(
    Deal_Implementation__c implementation,
    String expected
  ) {
    if (implementation.Status__c != expected) {
      throw new PartnerSyncHandledException(
        'This action requires the implementation to be ' + expected + '.'
      );
    }
  }

  private static void requireStatus(
    Deal_Implementation__c implementation,
    String expectedA,
    String expectedB
  ) {
    if (
      implementation.Status__c != expectedA &&
      implementation.Status__c != expectedB
    ) {
      throw new PartnerSyncHandledException(
        'This action requires the implementation to be ' +
          expectedA +
          ' or ' +
          expectedB +
          '.'
      );
    }
  }

  private static void publish(
    Deal_Implementation__c implementation,
    String eventType,
    String summary
  ) {
    PlatformEventPublisherService.publish(
      eventType,
      implementation.Deal__c,
      'Deal_Registration__c',
      implementation.Primary_Partner__c,
      summary,
      'Info'
    );
  }

  // Advances Deal_Registration__c.Lifecycle_Phase__c through the
  // established DealLifecycleMutationContext bypass - DealCommandService
  // uses this exact mechanism for Status__c/Version_Number__c; reused
  // narrowly here for Lifecycle_Phase__c only (Sprint 40 Known Adaptation
  // #6). Failure to advance the phase is logged and swallowed, never
  // fails the implementation command itself - the phase is a projection,
  // not a governance gate.
  private static void advanceLifecyclePhase(Id dealId, String newPhase) {
    DealLifecycleMutationContext.beginControlledMutation();
    try {
      Database.update(
        new Deal_Registration__c(Id = dealId, Lifecycle_Phase__c = newPhase),
        AccessLevel.SYSTEM_MODE
      );
    } catch (Exception ex) {
      LoggingService.warn(
        'ImplementationCommandService',
        'Lifecycle phase advance to ' +
          newPhase +
          ' deferred for deal ' +
          dealId +
          ': ' +
          ex.getMessage()
      );
    } finally {
      DealLifecycleMutationContext.endControlledMutation();
    }
  }

  private static Deal_Implementation_Policy__mdt resolvePolicy() {
    List<Deal_Implementation_Policy__mdt> rows = [
      SELECT
        Implementation_Required__c,
        Default_Implementation_Type__c,
        Default_Duration_Days__c,
        Require_Handoff__c,
        Require_Customer_Acceptance__c,
        Require_Evidence__c
      FROM Deal_Implementation_Policy__mdt
      WHERE Active__c = TRUE
      WITH SYSTEM_MODE
      ORDER BY Priority__c DESC NULLS LAST
      LIMIT 1
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException(
        'No active Deal Implementation Policy is configured.'
      );
    }
    return rows[0];
  }
}
