/*
 * Covers ImplementationCommandService: policy-gated creation, the
 * not-required no-op, idempotent re-creation for an already-active deal,
 * the full Start->Complete happy path (including Lifecycle_Phase__c and
 * Implementation_Status__c projection), and Complete blocked by an open
 * required milestone or an open issue.
 */
@IsTest
private class ImplementationCommandServiceTest {
  @IsTest
  static void createsAnImplementationWhenPolicyRequiresIt() {
    Deal_Registration__c deal = approvedDealWithPrimaryOpportunity();

    Test.startTest();
    Deal_Implementation__c implementation = ImplementationCommandService.execute(
      createCommand(deal.Id)
    );
    Test.stopTest();

    Assert.isNotNull(implementation);
    Assert.areEqual('Planned', implementation.Status__c);
    Assert.areEqual('Healthy', implementation.Health__c);

    Deal_Registration__c refreshedDeal = [
      SELECT Lifecycle_Phase__c, Implementation_Status__c
      FROM Deal_Registration__c
      WHERE Id = :deal.Id
    ];
    Assert.areEqual('Implementation', refreshedDeal.Lifecycle_Phase__c);
    Assert.areEqual('Planned', refreshedDeal.Implementation_Status__c);
  }

  @IsTest
  static void createNoOpsWhenPolicyDoesNotRequireImplementation() {
    Deal_Registration__c deal = approvedDealWithPrimaryOpportunity();
    ImplementationCommandService.testImplementationRequiredOverride = false;

    Test.startTest();
    Deal_Implementation__c implementation = ImplementationCommandService.execute(
      createCommand(deal.Id)
    );
    Test.stopTest();

    Assert.isNull(implementation);
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM Deal_Implementation__c WHERE Deal__c = :deal.Id]
    );
  }

  @IsTest
  static void createIsIdempotentForAnAlreadyActiveDeal() {
    Deal_Registration__c deal = approvedDealWithPrimaryOpportunity();

    Test.startTest();
    ImplementationCommandService.execute(createCommand(deal.Id));
    Deal_Implementation__c second = ImplementationCommandService.execute(
      createCommand(deal.Id)
    );
    Test.stopTest();

    Assert.isNull(second);
    Assert.areEqual(
      1,
      [SELECT COUNT() FROM Deal_Implementation__c WHERE Deal__c = :deal.Id]
    );
  }

  @IsTest
  static void fullStartToCompleteHappyPath() {
    Deal_Registration__c deal = approvedDealWithPrimaryOpportunity();
    Deal_Implementation__c implementation = ImplementationCommandService.execute(
      createCommand(deal.Id)
    );
    // create() auto-generates the seeded template milestone set (Sprint
    // 40 Phase 4) - completing them directly by DML here since this
    // test's focus is the implementation lifecycle, not milestone-by-
    // milestone completion (covered by ImplementationMilestoneCommandServiceTest).
    List<Implementation_Milestone__c> requiredMilestones = [
      SELECT Id
      FROM Implementation_Milestone__c
      WHERE Implementation__c = :implementation.Id AND Required__c = TRUE
    ];
    for (Implementation_Milestone__c milestone : requiredMilestones) {
      milestone.Status__c = 'Completed';
    }
    update requiredMilestones;

    User internalUser = internalUser();
    Test.startTest();
    System.runAs(internalUser) {
      ImplementationCommandService.execute(
        actionCommand(implementation.Id, 'Start', 0)
      );
      ImplementationCommandService.execute(
        actionCommand(implementation.Id, 'Complete', 1)
      );
    }
    Test.stopTest();

    Deal_Implementation__c refreshed = [
      SELECT Status__c, Actual_Start_Date__c, Actual_Completion_Date__c
      FROM Deal_Implementation__c
      WHERE Id = :implementation.Id
    ];
    Assert.areEqual('Completed', refreshed.Status__c);
    Assert.isNotNull(refreshed.Actual_Start_Date__c);
    Assert.isNotNull(refreshed.Actual_Completion_Date__c);

    Deal_Registration__c refreshedDeal = [
      SELECT Lifecycle_Phase__c, Implementation_Status__c
      FROM Deal_Registration__c
      WHERE Id = :deal.Id
    ];
    Assert.areEqual('Customer Success', refreshedDeal.Lifecycle_Phase__c);
    Assert.areEqual('Completed', refreshedDeal.Implementation_Status__c);
  }

  @IsTest
  static void completeIsBlockedByAnOpenRequiredMilestone() {
    Deal_Registration__c deal = approvedDealWithPrimaryOpportunity();
    Deal_Implementation__c implementation = ImplementationCommandService.execute(
      createCommand(deal.Id)
    );
    insert new Implementation_Milestone__c(
      Implementation__c = implementation.Id,
      Milestone_Type__c = 'Kickoff',
      Name__c = 'Kickoff',
      Status__c = 'Not Started',
      Required__c = true,
      Version_Number__c = 0
    );

    User internalUser = internalUser();
    System.runAs(internalUser) {
      ImplementationCommandService.execute(
        actionCommand(implementation.Id, 'Start', 0)
      );
      try {
        ImplementationCommandService.execute(
          actionCommand(implementation.Id, 'Complete', 1)
        );
        Assert.fail(
          'Expected completion to be blocked by an open required milestone.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('milestones'));
      }
    }
  }

  @IsTest
  static void completeIsBlockedByAnOpenIssue() {
    Deal_Registration__c deal = approvedDealWithPrimaryOpportunity();
    Deal_Implementation__c implementation = ImplementationCommandService.execute(
      createCommand(deal.Id)
    );
    insert new Implementation_Issue__c(
      Implementation__c = implementation.Id,
      Issue_Type__c = 'Scope',
      Severity__c = 'High',
      Status__c = 'Open',
      Title__c = 'Scope clarification needed'
    );

    User internalUser = internalUser();
    System.runAs(internalUser) {
      ImplementationCommandService.execute(
        actionCommand(implementation.Id, 'Start', 0)
      );
      try {
        ImplementationCommandService.execute(
          actionCommand(implementation.Id, 'Complete', 1)
        );
        Assert.fail('Expected completion to be blocked by an open issue.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('open issues'));
      }
    }
  }

  // Concurrency pair (doc §40.53): a second actor's Cancel attempt, still
  // holding the pre-Start version number, is rejected rather than
  // silently clobbering the Start that already committed.
  @IsTest
  static void cancelAfterConcurrentStartFailsOnStaleVersion() {
    Deal_Registration__c deal = approvedDealWithPrimaryOpportunity();
    Deal_Implementation__c implementation = ImplementationCommandService.execute(
      createCommand(deal.Id)
    );

    User internalUser = internalUser();
    System.runAs(internalUser) {
      ImplementationCommandService.execute(
        actionCommand(implementation.Id, 'Start', 0)
      );

      try {
        ImplementationCommandService.execute(
          actionCommand(implementation.Id, 'Cancel', 0)
        );
        Assert.fail(
          'Expected cancel to be rejected after the concurrent start.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('changed'));
      }
    }

    Assert.areEqual(
      'In Progress',
      [
        SELECT Status__c
        FROM Deal_Implementation__c
        WHERE Id = :implementation.Id
      ]
      .Status__c
    );
  }

  // Concurrency pair (doc §40.53): a Critical issue raised after Start but
  // before the Complete attempt still blocks completion, proving the guard
  // reads the issue roster fresh rather than a stale snapshot taken at
  // Start.
  @IsTest
  static void completeIsBlockedByACriticalIssueRaisedConcurrently() {
    Deal_Registration__c deal = approvedDealWithPrimaryOpportunity();
    Deal_Implementation__c implementation = ImplementationCommandService.execute(
      createCommand(deal.Id)
    );
    List<Implementation_Milestone__c> requiredMilestones = [
      SELECT Id
      FROM Implementation_Milestone__c
      WHERE Implementation__c = :implementation.Id AND Required__c = TRUE
    ];
    for (Implementation_Milestone__c milestone : requiredMilestones) {
      milestone.Status__c = 'Completed';
    }
    update requiredMilestones;

    User internalUser = internalUser();
    System.runAs(internalUser) {
      ImplementationCommandService.execute(
        actionCommand(implementation.Id, 'Start', 0)
      );

      ImplementationIssueCommand raise = new ImplementationIssueCommand();
      raise.implementationId = implementation.Id;
      raise.issueType = 'Technical';
      raise.severity = 'Critical';
      raise.title = 'Data migration failed validation';
      ImplementationIssueCommandService.raise(raise);

      try {
        ImplementationCommandService.execute(
          actionCommand(implementation.Id, 'Complete', 1)
        );
        Assert.fail(
          'Expected completion to be blocked by the concurrently-raised critical issue.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('open issues'));
      }
    }
  }

  private static Deal_Registration__c approvedDealWithPrimaryOpportunity() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert new List<Account>{ partner, customer };

    Opportunity opportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      partner.Id,
      null
    );
    insert opportunity;

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      partner.Id,
      null,
      opportunity.Id
    );
    deal.Status__c = 'Approved';
    insert deal;

    insert new Deal_Opportunity__c(
      Deal__c = deal.Id,
      Opportunity__c = opportunity.Id,
      Partner_Account__c = partner.Id,
      Relationship_Type__c = 'Primary',
      Primary__c = true,
      Current__c = true,
      Relationship_Key__c = deal.Id + '|' + opportunity.Id,
      Version_Number__c = 0
    );

    return deal;
  }

  private static ImplementationCommand createCommand(Id dealId) {
    ImplementationCommand command = new ImplementationCommand();
    command.action = 'Create';
    command.dealId = dealId;
    return command;
  }

  private static ImplementationCommand actionCommand(
    Id implementationId,
    String action,
    Integer expectedVersion
  ) {
    ImplementationCommand command = new ImplementationCommand();
    command.action = action;
    command.implementationId = implementationId;
    command.expectedVersion = expectedVersion;
    command.reason = 'Test reason.';
    return command;
  }

  private static User internalUser() {
    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Manage_Implementation',
      true
    );
    return channelManager;
  }
}
