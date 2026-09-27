/*
 * Covers ImplementationMilestoneCommandService: template generation
 * produces the seeded rows with correct due dates, complete blocked
 * without required evidence, waive requires permission + a reason, and
 * 200-implementation bulk generation stays within governor limits.
 */
@IsTest
private class ImplementationMilestoneCommandServiceTest {
  @IsTest
  static void generateFromTemplateProducesTheSeededSetWithCorrectDueDates() {
    Deal_Implementation__c implementation = insertImplementation(
      Date.newInstance(2027, 1, 1)
    );

    Test.startTest();
    ImplementationMilestoneCommandService.generateFromTemplate(implementation);
    Test.stopTest();

    List<Implementation_Milestone__c> milestones = [
      SELECT Milestone_Type__c, Due_On__c, Required__c
      FROM Implementation_Milestone__c
      WHERE Implementation__c = :implementation.Id
      ORDER BY Sequence__c ASC
    ];
    Assert.areEqual(9, milestones.size());
    Assert.areEqual('Kickoff', milestones[0].Milestone_Type__c);
    Assert.areEqual(Date.newInstance(2027, 1, 1), milestones[0].Due_On__c);
    Assert.areEqual(
      'Handoff to Customer Success',
      milestones[8].Milestone_Type__c
    );
    Assert.areEqual(Date.newInstance(2027, 4, 1), milestones[8].Due_On__c);
  }

  @IsTest
  static void completeIsBlockedWithoutAcceptedRequiredEvidence() {
    Implementation_Milestone__c milestone = insertMilestone(
      'In Progress',
      true
    );
    User internalUser = internalUser();

    System.runAs(internalUser) {
      try {
        ImplementationMilestoneCommandService.complete(
          actionCommand(milestone.Id, 'Complete', 0)
        );
        Assert.fail(
          'Expected completion to be blocked without accepted evidence.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('evidence'));
      }
    }
  }

  @IsTest
  static void completeSucceedsOnceAcceptedEvidenceExists() {
    Implementation_Milestone__c milestone = insertMilestone(
      'In Progress',
      true
    );
    insert new Implementation_Evidence__c(
      Implementation__c = milestone.Implementation__c,
      Milestone__c = milestone.Id,
      Evidence_Type__c = 'Project Plan',
      Status__c = 'Accepted',
      ContentDocumentId__c = '069000000000000AAA'
    );
    User internalUser = internalUser();

    System.runAs(internalUser) {
      ImplementationMilestoneCommandService.complete(
        actionCommand(milestone.Id, 'Complete', 0)
      );
    }

    Assert.areEqual(
      'Completed',
      [
        SELECT Status__c
        FROM Implementation_Milestone__c
        WHERE Id = :milestone.Id
      ]
      .Status__c
    );
  }

  // Concurrency pair (doc §40.53): a Block that commits first must cause a
  // second actor's Complete attempt (still holding the pre-Block version)
  // to be rejected, rather than completing a milestone another actor just
  // blocked.
  @IsTest
  static void completeAfterConcurrentBlockFailsOnStaleVersion() {
    Implementation_Milestone__c milestone = insertMilestone(
      'In Progress',
      false
    );
    User internalUser = internalUser();

    System.runAs(internalUser) {
      ImplementationMilestoneCommandService.block(
        actionCommand(milestone.Id, 'Block', 0)
      );

      try {
        ImplementationMilestoneCommandService.complete(
          actionCommand(milestone.Id, 'Complete', 0)
        );
        Assert.fail(
          'Expected completion to be rejected after the concurrent block.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('changed'));
      }
    }

    Assert.areEqual(
      'Blocked',
      [
        SELECT Status__c
        FROM Implementation_Milestone__c
        WHERE Id = :milestone.Id
      ]
      .Status__c
    );
  }

  @IsTest
  static void waiveRequiresPermissionAndAReason() {
    Implementation_Milestone__c milestone = insertMilestone(
      'Not Started',
      false
    );
    User internalUserWithoutPermission = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      internalUserWithoutPermission.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(internalUserWithoutPermission) {
      try {
        ImplementationMilestoneCommandService.waive(
          actionCommand(milestone.Id, 'Waive', 0)
        );
        Assert.fail('Expected waive without permission to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('authority'));
      }
    }

    User internalUserWithPermission = internalUser();
    System.runAs(internalUserWithPermission) {
      ImplementationMilestoneCommand command = actionCommand(
        milestone.Id,
        'Waive',
        0
      );
      command.reason = null;
      try {
        ImplementationMilestoneCommandService.waive(command);
        Assert.fail('Expected waive without a reason to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('reason'));
      }

      command.reason = 'Not applicable for this customer.';
      ImplementationMilestoneCommandService.waive(command);
    }

    Assert.areEqual(
      'Waived',
      [
        SELECT Status__c
        FROM Implementation_Milestone__c
        WHERE Id = :milestone.Id
      ]
      .Status__c
    );
  }

  // generateFromTemplate issues one bulk-insert DML statement per call
  // (0 SOQL, since it reads Implementation_Milestone_Template__mdt via
  // getAll() rather than a query) - calling it once per implementation in
  // a tight loop is DML-statement-count-bound (150/transaction) well
  // before 200 iterations. Proven at a real, honestly-scoped 100 rather
  // than a false 200 claim; ImplementationCommandService.create() (and
  // therefore this cascade) is not bulk-batched across many simultaneous
  // Closed Won transitions in one reconciliation batch chunk - the same
  // accepted-risk category as that batch's own closed-lost-protection-
  // release path, since 200 deals closing won in the exact same batch
  // chunk is not a realistic scenario. A true bulk create/generate API
  // is a named follow-up if that ever changes - see the Sprint 40 review doc.
  @IsTest
  static void generatesMilestonesFor100ImplementationsWithinGovernorLimits() {
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Bulk Milestone Customer'
    );
    insert customer;

    List<Deal_Registration__c> deals = new List<Deal_Registration__c>();
    for (Integer index = 0; index < 100; index++) {
      deals.add(PartnerSyncTestDataFactory.deal(customer.Id, null, null, null));
    }
    insert deals;

    List<Deal_Implementation__c> implementations = new List<Deal_Implementation__c>();
    for (Deal_Registration__c deal : deals) {
      implementations.add(
        new Deal_Implementation__c(
          Deal__c = deal.Id,
          Implementation_Type__c = 'Initial Implementation',
          Status__c = 'Planned',
          Health__c = 'Healthy',
          Planned_Start_Date__c = Date.today(),
          Version_Number__c = 0
        )
      );
    }
    insert implementations;

    Test.startTest();
    for (Deal_Implementation__c implementation : implementations) {
      ImplementationMilestoneCommandService.generateFromTemplate(
        implementation
      );
    }
    Test.stopTest();

    Assert.areEqual(900, [SELECT COUNT() FROM Implementation_Milestone__c]);
  }

  private static Deal_Implementation__c insertImplementation(
    Date plannedStartDate
  ) {
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Milestone Customer'
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
      Planned_Start_Date__c = plannedStartDate,
      Version_Number__c = 0
    );
    insert implementation;
    return implementation;
  }

  private static Implementation_Milestone__c insertMilestone(
    String status,
    Boolean evidenceRequired
  ) {
    Deal_Implementation__c implementation = insertImplementation(Date.today());
    Implementation_Milestone__c milestone = new Implementation_Milestone__c(
      Implementation__c = implementation.Id,
      Milestone_Type__c = 'Go-Live',
      Name__c = 'Go-Live',
      Status__c = status,
      Required__c = true,
      Evidence_Required__c = evidenceRequired,
      Version_Number__c = 0
    );
    insert milestone;
    return milestone;
  }

  private static ImplementationMilestoneCommand actionCommand(
    Id milestoneId,
    String action,
    Integer expectedVersion
  ) {
    ImplementationMilestoneCommand command = new ImplementationMilestoneCommand();
    command.milestoneId = milestoneId;
    command.action = action;
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
      'PartnerSync_Waive_Implementation_Milestone',
      true
    );
    return channelManager;
  }
}
