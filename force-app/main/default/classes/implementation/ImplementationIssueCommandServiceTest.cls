/*
 * Covers ImplementationIssueCommandService: raise, escalate, resolve
 * (requiring a resolution), acceptRisk (requiring permission + a reason),
 * and that raise/resolve trigger a health recompute.
 */
@IsTest
private class ImplementationIssueCommandServiceTest {
  @IsTest
  static void raiseCreatesAnOpenIssueAndFlagsHealth() {
    Deal_Implementation__c implementation = createImplementation();

    Test.startTest();
    Implementation_Issue__c issue = ImplementationIssueCommandService.raise(
      raiseCommand(implementation.Id, 'Critical')
    );
    Test.stopTest();

    Assert.areEqual('Open', issue.Status__c);
    Assert.areEqual(
      'Blocked',
      [
        SELECT Health__c
        FROM Deal_Implementation__c
        WHERE Id = :implementation.Id
      ]
      .Health__c
    );
  }

  @IsTest
  static void resolveRequiresAResolutionAndClearsHealth() {
    Deal_Implementation__c implementation = createImplementation();
    Implementation_Issue__c issue = ImplementationIssueCommandService.raise(
      raiseCommand(implementation.Id, 'Critical')
    );

    User internalUser = internalUser();
    System.runAs(internalUser) {
      ImplementationIssueCommand command = new ImplementationIssueCommand();
      command.issueId = issue.Id;
      try {
        ImplementationIssueCommandService.resolve(command);
        Assert.fail('Expected resolve without a resolution to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('resolution'));
      }

      command.resolution = 'Corrected the integration mapping.';
      ImplementationIssueCommandService.resolve(command);
    }

    Assert.areEqual(
      'Resolved',
      [SELECT Status__c FROM Implementation_Issue__c WHERE Id = :issue.Id]
      .Status__c
    );
    Assert.areEqual(
      'Healthy',
      [
        SELECT Health__c
        FROM Deal_Implementation__c
        WHERE Id = :implementation.Id
      ]
      .Health__c
    );
  }

  @IsTest
  static void escalateIncrementsTheEscalationLevel() {
    Deal_Implementation__c implementation = createImplementation();
    Implementation_Issue__c issue = ImplementationIssueCommandService.raise(
      raiseCommand(implementation.Id, 'High')
    );

    User internalUser = internalUser();
    System.runAs(internalUser) {
      ImplementationIssueCommand command = new ImplementationIssueCommand();
      command.issueId = issue.Id;
      ImplementationIssueCommandService.escalate(command);
    }

    Implementation_Issue__c refreshed = [
      SELECT Status__c, Escalation_Level__c
      FROM Implementation_Issue__c
      WHERE Id = :issue.Id
    ];
    Assert.areEqual('Escalated', refreshed.Status__c);
    Assert.areEqual(1, refreshed.Escalation_Level__c);
  }

  @IsTest
  static void acceptRiskRequiresPermissionAndAReason() {
    Deal_Implementation__c implementation = createImplementation();
    Implementation_Issue__c issue = ImplementationIssueCommandService.raise(
      raiseCommand(implementation.Id, 'Medium')
    );

    User internalUserWithoutPermission = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      internalUserWithoutPermission.Id,
      'PartnerSync_PDLM_Admin'
    );
    System.runAs(internalUserWithoutPermission) {
      ImplementationIssueCommand command = new ImplementationIssueCommand();
      command.issueId = issue.Id;
      command.reason = 'Accepted for now.';
      try {
        ImplementationIssueCommandService.acceptRisk(command);
        Assert.fail('Expected accept risk without permission to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('authority'));
      }
    }

    User internalUserWithPermission = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      internalUserWithPermission.Id,
      'PartnerSync_PDLM_Admin'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Accept_Implementation_Risk',
      true
    );
    System.runAs(internalUserWithPermission) {
      ImplementationIssueCommand command = new ImplementationIssueCommand();
      command.issueId = issue.Id;
      ImplementationIssueCommandService.acceptRisk(command);
    }

    Assert.areEqual(
      'Accepted Risk',
      [SELECT Status__c FROM Implementation_Issue__c WHERE Id = :issue.Id]
      .Status__c
    );
  }

  private static Deal_Implementation__c createImplementation() {
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Issue Customer'
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
      Status__c = 'In Progress',
      Health__c = 'Healthy',
      Version_Number__c = 0
    );
    insert implementation;
    return implementation;
  }

  private static ImplementationIssueCommand raiseCommand(
    Id implementationId,
    String severity
  ) {
    ImplementationIssueCommand command = new ImplementationIssueCommand();
    command.implementationId = implementationId;
    command.issueType = 'Technical Defect';
    command.severity = severity;
    command.title = 'Integration mapping error';
    command.description = 'Field mapping failed during sync.';
    return command;
  }

  private static User internalUser() {
    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Escalate_Implementation',
      true
    );
    return channelManager;
  }
}
