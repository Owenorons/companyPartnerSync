@IsTest
private class DealCommandContractTest {
  @IsTest
  static void validatesRequiredEnvelopeFields() {
    DealCommand command = new DealCommand();
    try {
      command.validate();
      Assert.fail('Expected validation to fail.');
    } catch (DealLifecycleException ex) {
      Assert.isTrue(ex.getMessage().contains('identifiers'));
    }
  }

  @IsTest
  static void acceptsCompleteEnvelope() {
    Account account = new Account(Name = 'Command Contract Test');
    insert account;
    DealCommand command = new DealCommand();
    command.dealId = account.Id;
    command.aggregateId = command.dealId;
    command.aggregateType = DealLifecycleConstants.AGGREGATE_REGISTRATION;
    command.lifecycleDimension = DealLifecycleConstants.DIMENSION_REGISTRATION;
    command.commandType = 'Submit';
    command.commandKey = 'unit-test-command';
    command.validate();
    Assert.isNotNull(command.parameters);
  }

  @IsTest
  static void validatesTextEnvelopeFieldsAndReinitializesParameters() {
    Account account = new Account(Name = 'Envelope Branch Test');
    insert account;
    DealCommand command = new DealCommand();
    command.dealId = account.Id;
    command.aggregateId = account.Id;
    command.commandKey = 'branch-test';
    command.commandType = 'Submit';
    try {
      command.validate();
      Assert.fail('Expected aggregate validation failure.');
    } catch (DealLifecycleException ex) {
      Assert.isTrue(ex.getMessage().contains('Aggregate type'));
    }

    command.aggregateType = DealLifecycleConstants.AGGREGATE_REGISTRATION;
    command.lifecycleDimension = DealLifecycleConstants.DIMENSION_REGISTRATION;
    command.parameters = null;
    command.validate();
    Assert.isNotNull(command.parameters);

    command.commandKey = ''.leftPad(81, 'x');
    try {
      command.validate();
      Assert.fail('Expected command key validation failure.');
    } catch (DealLifecycleException ex) {
      Assert.isTrue(ex.getMessage().contains('80 characters'));
    }
  }

  @IsTest
  static void mutationContextUsesBalancedDepth() {
    Assert.isFalse(DealLifecycleMutationContext.isControlledMutation());
    DealLifecycleMutationContext.beginControlledMutation();
    DealLifecycleMutationContext.beginControlledMutation();
    Assert.isTrue(DealLifecycleMutationContext.isControlledMutation());
    DealLifecycleMutationContext.endControlledMutation();
    Assert.isTrue(DealLifecycleMutationContext.isControlledMutation());
    DealLifecycleMutationContext.endControlledMutation();
    Assert.isFalse(DealLifecycleMutationContext.isControlledMutation());
  }

  @IsTest
  static void migrationContextRequiresPermissionAndBalancesDepth() {
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Override_Lifecycle',
      false
    );
    try {
      DealLifecycleMutationContext.beginMigration();
      Assert.fail('Expected migration permission failure.');
    } catch (DealLifecycleException ex) {
      Assert.isTrue(ex.getMessage().contains('permission'));
    }

    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Override_Lifecycle',
      true
    );
    DealLifecycleMutationContext.beginMigration();
    Assert.isTrue(DealLifecycleMutationContext.isMigration());
    DealLifecycleMutationContext.endMigration();
    DealLifecycleMutationContext.endMigration();
    Assert.isFalse(DealLifecycleMutationContext.isMigration());
    DealLifecyclePermissionService.clearTestPermissions();
  }

  @IsTest
  static void coversControllerFactoryAndInProgressContracts() {
    try {
      DealCommandController.executeCommand(null);
      Assert.fail('Expected a handled request validation failure.');
    } catch (AuraHandledException ex) {
      Assert.isNotNull(ex);
    }
    try {
      DealCommandController.executeCommand('{invalid-json');
      Assert.fail('Expected a handled deserialization failure.');
    } catch (AuraHandledException ex) {
      Assert.isNotNull(ex);
    }

    for (
      String handlerName : new List<String>{
        null,
        'MissingDealHandler',
        'DealCommandResult'
      }
    ) {
      try {
        DealCommandHandlerFactory.getHandler(handlerName);
        Assert.fail('Expected handler configuration failure.');
      } catch (DealLifecycleException ex) {
        Assert.isNotNull(ex.getMessage());
      }
    }

    DealCommand command = new DealCommand();
    command.dealId = UserInfo.getUserId();
    command.aggregateId = command.dealId;
    command.commandKey = 'in-progress-contract';
    DealCommandResult result = DealCommandResult.inProgress(command);
    Assert.isTrue(result.accepted);
    Assert.isFalse(result.completed);
    Assert.isTrue(result.duplicateCommand);
    Assert.isTrue(result.retryable);
    Assert.areEqual(command.dealId, result.dealId);
    Assert.areEqual(command.aggregateId, result.aggregateId);
    Assert.areEqual(command.commandKey, result.commandKey);
  }
}
