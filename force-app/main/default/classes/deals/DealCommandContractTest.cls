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
}
