/*
 * Covers ImplementationHandoffCommandService: each rejection outcome
 * branch, a successful submit, accept transitioning the linked
 * implementation, and return requiring a reason and resetting state.
 */
@IsTest
private class ImplementationHandoffCommandServiceTest {
  @IsTest
  static void submitRejectsMissingInformation() {
    Deal_Implementation__c implementation = createImplementation();
    User internalUser = internalUser();

    ImplementationHandoffOutcome outcome;
    System.runAs(internalUser) {
      ImplementationHandoffCommand command = baseCommand(implementation.Id);
      command.customerObjectives = null;
      outcome = ImplementationHandoffCommandService.submit(command);
    }

    Assert.areEqual(
      ImplementationHandoffOutcome.INFORMATION_REQUIRED,
      outcome.outcome
    );
  }

  @IsTest
  static void submitRejectsMissingDeliveryOwner() {
    Deal_Implementation__c implementation = createImplementation();
    User internalUser = internalUser();

    ImplementationHandoffOutcome outcome;
    System.runAs(internalUser) {
      ImplementationHandoffCommand command = baseCommand(implementation.Id);
      command.deliveryOwnerId = null;
      outcome = ImplementationHandoffCommandService.submit(command);
    }

    Assert.areEqual(
      ImplementationHandoffOutcome.DELIVERY_OWNER_REQUIRED,
      outcome.outcome
    );
  }

  @IsTest
  static void submitRejectsMissingScope() {
    Deal_Implementation__c implementation = createImplementation();
    User internalUser = internalUser();

    ImplementationHandoffOutcome outcome;
    System.runAs(internalUser) {
      ImplementationHandoffCommand command = baseCommand(implementation.Id);
      command.scopeSummary = null;
      outcome = ImplementationHandoffCommandService.submit(command);
    }

    Assert.areEqual(
      ImplementationHandoffOutcome.SCOPE_INCOMPLETE,
      outcome.outcome
    );
  }

  @IsTest
  static void submitRejectsIncompleteRequiredEvidence() {
    Deal_Implementation__c implementation = createImplementation();
    User internalUser = internalUser();
    ImplementationHandoffCommandService.testRequireEvidenceOverride = true;

    ImplementationHandoffOutcome outcome;
    System.runAs(internalUser) {
      ImplementationHandoffCommand command = baseCommand(implementation.Id);
      command.requiredEvidenceComplete = false;
      outcome = ImplementationHandoffCommandService.submit(command);
    }

    Assert.areEqual(
      ImplementationHandoffOutcome.EVIDENCE_REQUIRED,
      outcome.outcome
    );
  }

  @IsTest
  static void submitSucceedsAndAcceptTransitionsTheImplementation() {
    Deal_Implementation__c implementation = createImplementation();
    User internalUser = internalUser();

    ImplementationHandoffOutcome outcome;
    System.runAs(internalUser) {
      outcome = ImplementationHandoffCommandService.submit(
        baseCommand(implementation.Id)
      );
    }
    Assert.areEqual(ImplementationHandoffOutcome.ACCEPTED, outcome.outcome);

    System.runAs(internalUser) {
      ImplementationHandoffCommand acceptCommand = new ImplementationHandoffCommand();
      acceptCommand.handoffId = outcome.handoff.Id;
      acceptCommand.expectedVersion = 0;
      ImplementationHandoffCommandService.accept(acceptCommand);
    }

    Assert.areEqual(
      'Accepted',
      [
        SELECT Status__c
        FROM Deal_Implementation_Handoff__c
        WHERE Id = :outcome.handoff.Id
      ]
      .Status__c
    );
    Assert.areEqual(
      'Not Started',
      [
        SELECT Status__c
        FROM Deal_Implementation__c
        WHERE Id = :implementation.Id
      ]
      .Status__c
    );
  }

  @IsTest
  static void returnRequiresAReasonAndResetsStatus() {
    Deal_Implementation__c implementation = createImplementation();
    User internalUser = internalUser();

    ImplementationHandoffOutcome outcome;
    System.runAs(internalUser) {
      outcome = ImplementationHandoffCommandService.submit(
        baseCommand(implementation.Id)
      );

      ImplementationHandoffCommand returnCommand = new ImplementationHandoffCommand();
      returnCommand.handoffId = outcome.handoff.Id;
      returnCommand.expectedVersion = 0;
      try {
        ImplementationHandoffCommandService.doReturn(returnCommand);
        Assert.fail('Expected a return without a reason to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('reason'));
      }

      returnCommand.reason = 'Missing commercial approval.';
      ImplementationHandoffCommandService.doReturn(returnCommand);
    }

    Deal_Implementation_Handoff__c refreshed = [
      SELECT Status__c, Returned_Reason__c
      FROM Deal_Implementation_Handoff__c
      WHERE Id = :outcome.handoff.Id
    ];
    Assert.areEqual('Returned', refreshed.Status__c);
    Assert.areEqual(
      'Missing commercial approval.',
      refreshed.Returned_Reason__c
    );
  }

  // Concurrency pair (doc §40.53): an Accept that commits first must cause
  // a second actor's Return attempt (still holding the pre-Accept version)
  // to be rejected, rather than returning a handoff another actor already
  // accepted.
  @IsTest
  static void returnAfterConcurrentAcceptFailsOnStaleVersion() {
    Deal_Implementation__c implementation = createImplementation();
    User internalUser = internalUser();

    ImplementationHandoffOutcome outcome;
    System.runAs(internalUser) {
      outcome = ImplementationHandoffCommandService.submit(
        baseCommand(implementation.Id)
      );

      ImplementationHandoffCommand acceptCommand = new ImplementationHandoffCommand();
      acceptCommand.handoffId = outcome.handoff.Id;
      acceptCommand.expectedVersion = 0;
      ImplementationHandoffCommandService.accept(acceptCommand);

      ImplementationHandoffCommand returnCommand = new ImplementationHandoffCommand();
      returnCommand.handoffId = outcome.handoff.Id;
      returnCommand.expectedVersion = 0;
      returnCommand.reason = 'Missing commercial approval.';
      try {
        ImplementationHandoffCommandService.doReturn(returnCommand);
        Assert.fail(
          'Expected the return to be rejected after the concurrent accept.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('changed'));
      }
    }

    Assert.areEqual(
      'Accepted',
      [
        SELECT Status__c
        FROM Deal_Implementation_Handoff__c
        WHERE Id = :outcome.handoff.Id
      ]
      .Status__c
    );
  }

  private static Deal_Implementation__c createImplementation() {
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Handoff Customer'
    );
    insert customer;
    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      null,
      null,
      null
    );
    insert deal;
    Deal_Implementation__c implementation = new Deal_Implementation__c(
      Deal__c = deal.Id,
      Implementation_Type__c = 'Initial Implementation',
      Status__c = 'Planned',
      Health__c = 'Healthy',
      Version_Number__c = 0
    );
    insert implementation;
    return implementation;
  }

  private static ImplementationHandoffCommand baseCommand(Id implementationId) {
    ImplementationHandoffCommand command = new ImplementationHandoffCommand();
    command.implementationId = implementationId;
    command.customerObjectives = 'Reduce manual reporting time.';
    command.solutionSummary = 'Deploy the standard reporting package.';
    command.commercialSummary = 'Annual contract, $50,000.';
    command.scopeSummary = 'Configuration and training only.';
    command.deliveryOwnerId = UserInfo.getUserId();
    command.targetStartDate = Date.today().addDays(7);
    command.targetCompletionDate = Date.today().addDays(97);
    return command;
  }

  private static User internalUser() {
    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Accept_Implementation_Handoff',
      true
    );
    return channelManager;
  }
}
