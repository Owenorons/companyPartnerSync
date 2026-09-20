@IsTest
private class DealCommandServiceTest {
  @IsTest
  static void executesAndDeduplicatesAggregateCommand() {
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Draft',
      Lifecycle_Phase__c = 'Registration',
      Version_Number__c = 0
    );
    insert deal;
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Administer_PDLM',
      true
    );

    DealCommand command = buildCommand(deal.Id, 'initialize-command', 0);
    DealCommandResult first = DealCommandController.executeCommand(
      JSON.serialize(command)
    );
    DealCommandResult duplicate = DealCommandService.execute(command);

    Deal_Registration__c stored = [
      SELECT
        Status__c,
        Lifecycle_Phase__c,
        Current_Action_Required__c,
        Lifecycle_Health__c,
        Version_Number__c,
        Last_Lifecycle_Event__c
      FROM Deal_Registration__c
      WHERE Id = :deal.Id
    ];
    Assert.isTrue(first.completed);
    Assert.areEqual(1, first.resultingVersion);
    Assert.isTrue(duplicate.duplicateCommand);
    Assert.areEqual(first.eventId, duplicate.eventId);
    Assert.areEqual('Draft', stored.Status__c);
    Assert.areEqual('Registration', stored.Lifecycle_Phase__c);
    Assert.areEqual('Submit', stored.Current_Action_Required__c);
    Assert.areEqual('Healthy', stored.Lifecycle_Health__c);
    Assert.areEqual(1, stored.Version_Number__c);
    Assert.areEqual('DealLifecycleInitialized', stored.Last_Lifecycle_Event__c);
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Deal_Command_Execution__c
        WHERE Command_Key__c = 'initialize-command'
      ]
    );
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Deal_Event__c
        WHERE Command_Key__c = 'initialize-command'
      ]
    );
    DealLifecyclePermissionService.clearTestPermissions();
  }

  @IsTest
  static void rejectsVersionAndPermissionFailures() {
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Draft',
      Lifecycle_Phase__c = 'Registration',
      Version_Number__c = 2
    );
    insert deal;

    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Administer_PDLM',
      true
    );
    try {
      DealCommandService.execute(buildCommand(deal.Id, 'stale-command', 1));
      Assert.fail('Expected version conflict.');
    } catch (DealLifecycleException ex) {
      Assert.isTrue(ex.getMessage().contains('changed by another user'));
    }

    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Administer_PDLM',
      false
    );
    try {
      DealCommandService.execute(buildCommand(deal.Id, 'denied-command', 2));
      Assert.fail('Expected permission failure.');
    } catch (DealLifecycleException ex) {
      Assert.isTrue(ex.getMessage().contains('not authorised'));
    }
    DealLifecyclePermissionService.clearTestPermissions();
  }

  @IsTest
  static void rejectsUnsupportedAggregateAndInvalidTransition() {
    Deal_Registration__c deal = new Deal_Registration__c(Status__c = 'Draft');
    insert deal;
    DealCommand command = buildCommand(deal.Id, 'unsupported-command', 0);
    command.aggregateType = 'Deal Review';
    try {
      DealCommandService.execute(command);
      Assert.fail('Expected unsupported aggregate failure.');
    } catch (DealLifecycleException ex) {
      Assert.isTrue(ex.getMessage().contains('supports'));
    }

    command = buildCommand(deal.Id, 'invalid-action-command', 0);
    command.commandType = 'Not Configured';
    try {
      DealCommandService.execute(command);
      Assert.fail('Expected invalid transition failure.');
    } catch (DealLifecycleException ex) {
      Assert.isTrue(ex.getMessage().contains('not permitted'));
    }
  }

  @IsTest
  static void returnsInProgressForReservedDuplicate() {
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Draft',
      Version_Number__c = 0
    );
    insert deal;
    insert new Deal_Command_Execution__c(
      Command_Key__c = 'processing-command',
      Deal__c = deal.Id,
      Aggregate_Type__c = DealLifecycleConstants.AGGREGATE_REGISTRATION,
      Aggregate_Id__c = String.valueOf(deal.Id),
      Command_Type__c = 'Initialize Lifecycle',
      Status__c = 'Processing',
      Expected_Version__c = 0,
      Requested_On__c = System.now()
    );

    DealCommandResult result = DealCommandService.execute(
      buildCommand(deal.Id, 'processing-command', 0)
    );
    Assert.isTrue(result.accepted);
    Assert.isFalse(result.completed);
    Assert.isTrue(result.retryable);
    Assert.areEqual(
      DealLifecycleConstants.OUTCOME_COMMAND_IN_PROGRESS,
      result.outcome
    );
  }

  @IsTest
  static void rejectsAggregateMismatchLockAndDimension() {
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Draft',
      Version_Number__c = 0
    );
    insert deal;
    Account unrelated = new Account(Name = 'Unrelated Aggregate');
    insert unrelated;

    DealCommand mismatch = buildCommand(deal.Id, 'mismatch-command', 0);
    mismatch.aggregateId = unrelated.Id;
    assertLifecycleFailure(mismatch, 'does not belong');

    DealCommand dimension = buildCommand(deal.Id, 'dimension-command', 0);
    dimension.lifecycleDimension = 'Approval';
    assertLifecycleFailure(dimension, 'supports');

    deal.Lifecycle_Locked__c = true;
    deal.Lifecycle_Lock_Reason__c = 'Compliance hold';
    DealLifecycleMutationContext.beginControlledMutation();
    try {
      update deal;
    } finally {
      DealLifecycleMutationContext.endControlledMutation();
    }
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Administer_PDLM',
      true
    );
    assertLifecycleFailure(
      buildCommand(deal.Id, 'locked-command', 0),
      'locked'
    );
    DealLifecyclePermissionService.clearTestPermissions();
  }

  @IsTest
  static void executesUsingProductionUserModeAccessPath() {
    User adminUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      adminUser.Id,
      'PartnerSync_Internal_Admin'
    );
    System.runAs(adminUser) {
      Deal_Registration__c deal = new Deal_Registration__c(
        Status__c = 'Draft',
        Lifecycle_Phase__c = 'Registration',
        Version_Number__c = 0
      );
      insert deal;
      DealLifecyclePermissionService.setTestPermission(
        'PartnerSync_Administer_PDLM',
        true
      );
      DealCommandService.useSystemModeForTests = false;
      try {
        DealCommandResult result = DealCommandService.execute(
          buildCommand(deal.Id, 'user-mode-command', 0)
        );
        Assert.isTrue(result.completed);
        Assert.areEqual(1, result.resultingVersion);
      } finally {
        DealCommandService.useSystemModeForTests = true;
        DealLifecyclePermissionService.clearTestPermissions();
      }
    }
  }

  private static void assertLifecycleFailure(
    DealCommand command,
    String expectedMessage
  ) {
    try {
      DealCommandService.execute(command);
      Assert.fail('Expected command failure containing: ' + expectedMessage);
    } catch (DealLifecycleException ex) {
      Assert.isTrue(ex.getMessage().contains(expectedMessage), ex.getMessage());
    }
  }

  private static DealCommand buildCommand(
    Id dealId,
    String key,
    Integer version
  ) {
    DealCommand command = new DealCommand();
    command.dealId = dealId;
    command.aggregateId = dealId;
    command.aggregateType = DealLifecycleConstants.AGGREGATE_REGISTRATION;
    command.lifecycleDimension = DealLifecycleConstants.DIMENSION_REGISTRATION;
    command.commandType = 'Initialize Lifecycle';
    command.commandKey = key;
    command.expectedVersion = version;
    command.source = 'Apex';
    return command;
  }
}
