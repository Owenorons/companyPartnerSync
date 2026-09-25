@IsTest
private class ApprovalServiceTest {
  private static final String DEAL_OBJECT = 'Deal_Registration__c';

  @IsTest
  static void generatesVersionedCurrentPlan() {
    Deal_Registration__c deal = deal(100000);
    generateForDeal(deal);
    generateForDeal(deal);
    Approval_Plan__c currentPlan = [
      SELECT Version_Number__c
      FROM Approval_Plan__c
      WHERE
        Object_Name__c = :DEAL_OBJECT
        AND Target_Record_Id__c = :deal.Id
        AND Current__c = TRUE
      LIMIT 1
    ];
    Assert.areEqual(2, currentPlan.Version_Number__c);
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Approval_Plan__c
        WHERE
          Object_Name__c = :DEAL_OBJECT
          AND Target_Record_Id__c = :deal.Id
          AND Current__c = TRUE
      ]
    );
  }

  @IsTest
  static void completesConditionalApprovalWithAuthoritySnapshot() {
    Deal_Registration__c deal = deal(100000);
    generateForDeal(deal);
    Approval__c step = [
      SELECT Id, Version_Number__c
      FROM Approval__c
      WHERE Object_Name__c = :DEAL_OBJECT AND Target_Record_Id__c = :deal.Id
      LIMIT 1
    ];
    ApprovalCommand command = new ApprovalCommand();
    command.approvalId = step.Id;
    command.expectedVersion = Integer.valueOf(step.Version_Number__c);
    command.decision = 'Approved with Conditions';
    command.conditionType = 'Protection Blocking';
    command.conditionDescription = 'Obtain signed customer confirmation';

    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      ApprovalCommandService.complete(command);
    }

    Approval__c completed = [
      SELECT Status__c, Authority_Snapshot__c
      FROM Approval__c
      WHERE Id = :step.Id
    ];
    Assert.areEqual('Completed', completed.Status__c);
    Assert.isNotNull(completed.Authority_Snapshot__c);
    Assert.areEqual(
      1,
      [SELECT COUNT() FROM Approval_Condition__c WHERE Approval__c = :step.Id]
    );
    Assert.areEqual(
      'Approved with Conditions',
      [
        SELECT Status__c
        FROM Approval_Plan__c
        WHERE
          Object_Name__c = :DEAL_OBJECT
          AND Target_Record_Id__c = :deal.Id
          AND Current__c = TRUE
      ]
      .Status__c
    );
    Approval_Plan__c finalPlan = ApprovalFinalisationGuard.assertReady(
      DEAL_OBJECT,
      deal.Id,
      0
    );
    Assert.areEqual('Approved with Conditions', finalPlan.Status__c);
    System.runAs(channelManager) {
      try {
        ApprovalCommandService.complete(command);
        Assert.fail('Expected stale command rejection.');
      } catch (ApprovalCommandService.ApprovalCommandException expected) {
        Assert.isTrue(expected.getMessage().contains('changed'));
      }
    }
  }

  @IsTest
  static void permissionSetHolderCanCompleteRoleRoutedStep() {
    Deal_Registration__c deal = deal(100000);
    generateForDeal(deal);
    Approval__c step = [
      SELECT Id, Version_Number__c, Assigned_To__c, Approver_Permission_Set__c
      FROM Approval__c
      WHERE Object_Name__c = :DEAL_OBJECT AND Target_Record_Id__c = :deal.Id
      LIMIT 1
    ];
    Assert.isNull(step.Assigned_To__c);
    Assert.areEqual(
      'PartnerSync_Channel_Manager',
      step.Approver_Permission_Set__c
    );

    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    ApprovalCommand command = new ApprovalCommand();
    command.approvalId = step.Id;
    command.expectedVersion = Integer.valueOf(step.Version_Number__c);
    command.decision = 'Approved';

    System.runAs(channelManager) {
      ApprovalCommandService.complete(command);
    }

    Assert.areEqual(
      'Completed',
      [SELECT Status__c FROM Approval__c WHERE Id = :step.Id].Status__c
    );
  }

  @IsTest
  static void nonHolderCannotCompleteRoleRoutedStep() {
    Deal_Registration__c deal = deal(100000);
    generateForDeal(deal);
    Approval__c step = [
      SELECT Id, Version_Number__c
      FROM Approval__c
      WHERE Object_Name__c = :DEAL_OBJECT AND Target_Record_Id__c = :deal.Id
      LIMIT 1
    ];

    User plainInternalUser = TestUserFactory.createInternalUser();

    ApprovalCommand command = new ApprovalCommand();
    command.approvalId = step.Id;
    command.expectedVersion = Integer.valueOf(step.Version_Number__c);
    command.decision = 'Approved';

    System.runAs(plainInternalUser) {
      try {
        ApprovalCommandService.complete(command);
        Assert.fail('Expected authority rejection.');
      } catch (ApprovalCommandService.ApprovalCommandException expected) {
        Assert.isTrue(expected.getMessage().contains('lacks authority'));
      }
    }

    Assert.areEqual(
      'Pending',
      [SELECT Status__c FROM Approval__c WHERE Id = :step.Id].Status__c
    );
  }

  @IsTest
  static void rejectsDecisionAboveAuthority() {
    Deal_Registration__c deal = deal(600000);
    generateForDeal(deal);
    Assert.areEqual(
      0,
      [
        SELECT COUNT()
        FROM Approval__c
        WHERE Object_Name__c = :DEAL_OBJECT AND Target_Record_Id__c = :deal.Id
      ]
    );
    try {
      ApprovalFinalisationGuard.assertReady(DEAL_OBJECT, deal.Id, 0);
      Assert.fail('Expected pending plan rejection.');
    } catch (ApprovalFinalisationGuard.ApprovalPlanNotReadyException expected) {
      Assert.isTrue(expected.getMessage().contains('not final'));
    }
  }

  @IsTest
  static void rejectsMismatchedTargetVersionAndMissingDecisions() {
    Deal_Registration__c deal = deal(100000);
    generateForDeal(deal);
    Approval_Plan__c plan = [
      SELECT Id
      FROM Approval_Plan__c
      WHERE
        Object_Name__c = :DEAL_OBJECT
        AND Target_Record_Id__c = :deal.Id
        AND Current__c = TRUE
    ];
    plan.Status__c = 'Approved';
    update plan;
    try {
      ApprovalFinalisationGuard.assertReady(DEAL_OBJECT, deal.Id, 99);
      Assert.fail('Expected version mismatch.');
    } catch (ApprovalFinalisationGuard.ApprovalPlanNotReadyException expected) {
      Assert.isTrue(expected.getMessage().contains('different record version'));
    }
    delete [SELECT Id FROM Approval__c WHERE Plan__c = :plan.Id];
    try {
      ApprovalFinalisationGuard.assertReady(DEAL_OBJECT, deal.Id, 0);
      Assert.fail('Expected missing decision rejection.');
    } catch (ApprovalFinalisationGuard.ApprovalPlanNotReadyException expected) {
      Assert.isTrue(expected.getMessage().contains('no decisions'));
    }
  }

  @IsTest
  static void returnedDecisionPublishesApprovalPlanReturnedEvent() {
    Deal_Registration__c deal = deal(100000);
    generateForDeal(deal);
    Approval__c step = [
      SELECT Id, Version_Number__c
      FROM Approval__c
      WHERE Object_Name__c = :DEAL_OBJECT AND Target_Record_Id__c = :deal.Id
      LIMIT 1
    ];
    ApprovalCommand command = new ApprovalCommand();
    command.approvalId = step.Id;
    command.expectedVersion = Integer.valueOf(step.Version_Number__c);
    command.decision = 'Returned';
    command.reason = 'Missing supporting documentation';

    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    Test.startTest();
    System.runAs(channelManager) {
      ApprovalCommandService.complete(command);
    }
    Test.stopTest();

    Assert.areEqual(
      'Returned',
      [
        SELECT Status__c
        FROM Approval_Plan__c
        WHERE
          Object_Name__c = :DEAL_OBJECT
          AND Target_Record_Id__c = :deal.Id
          AND Current__c = TRUE
      ]
      .Status__c
    );
    Event_Publication__c publication = [
      SELECT Event_Type__c
      FROM Event_Publication__c
      WHERE Event_Type__c = 'ApprovalPlanReturned'
      LIMIT 1
    ];
    Assert.isNotNull(publication);
  }

  @IsTest
  static void rejectedDecisionDoesNotPublishApprovalPlanReturnedEvent() {
    Deal_Registration__c deal = deal(100000);
    generateForDeal(deal);
    Approval__c step = [
      SELECT Id, Version_Number__c
      FROM Approval__c
      WHERE Object_Name__c = :DEAL_OBJECT AND Target_Record_Id__c = :deal.Id
      LIMIT 1
    ];
    ApprovalCommand command = new ApprovalCommand();
    command.approvalId = step.Id;
    command.expectedVersion = Integer.valueOf(step.Version_Number__c);
    command.decision = 'Rejected';
    command.reason = 'Does not meet program criteria';

    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    Test.startTest();
    System.runAs(channelManager) {
      ApprovalCommandService.complete(command);
    }
    Test.stopTest();

    Assert.areEqual(
      'Rejected',
      [
        SELECT Status__c
        FROM Approval_Plan__c
        WHERE
          Object_Name__c = :DEAL_OBJECT
          AND Target_Record_Id__c = :deal.Id
          AND Current__c = TRUE
      ]
      .Status__c
    );
    Assert.areEqual(
      0,
      [
        SELECT COUNT()
        FROM Event_Publication__c
        WHERE Event_Type__c = 'ApprovalPlanReturned'
      ]
    );
  }

  private static void generateForDeal(Deal_Registration__c deal) {
    ApprovalPlanService.generate(
      DEAL_OBJECT,
      new Set<Id>{ deal.Id },
      new Map<Id, Decimal>{ deal.Id => deal.Estimated_Revenue__c },
      new Map<Id, String>{ deal.Id => 'Test Deal' },
      new Map<Id, Integer>{ deal.Id => 0 }
    );
  }

  private static Deal_Registration__c deal(Decimal amount) {
    Deal_Registration__c result = new Deal_Registration__c(
      Status__c = 'Under Review',
      Estimated_Revenue__c = amount
    );
    insert result;
    return result;
  }
}
