@IsTest
private class DealApprovalServiceTest {
  @IsTest
  static void generatesVersionedCurrentPlan() {
    Deal_Registration__c deal = deal(100000);
    DealApprovalPlanService.generate(new Set<Id>{ deal.Id });
    DealApprovalPlanService.generate(new Set<Id>{ deal.Id });
    Deal_Approval_Plan__c currentPlan = [
      SELECT Version_Number__c
      FROM Deal_Approval_Plan__c
      WHERE Deal__c = :deal.Id AND Current__c = TRUE
      LIMIT 1
    ];
    Assert.areEqual(2, currentPlan.Version_Number__c);
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Deal_Approval_Plan__c
        WHERE Deal__c = :deal.Id AND Current__c = TRUE
      ]
    );
  }

  @IsTest
  static void completesConditionalApprovalWithAuthoritySnapshot() {
    Deal_Registration__c deal = deal(100000);
    DealApprovalPlanService.generate(new Set<Id>{ deal.Id });
    Deal_Approval__c step = [
      SELECT Id, Version_Number__c
      FROM Deal_Approval__c
      WHERE Deal__c = :deal.Id
      LIMIT 1
    ];
    DealApprovalCommand command = new DealApprovalCommand();
    command.approvalId = step.Id;
    command.expectedVersion = Integer.valueOf(step.Version_Number__c);
    command.decision = 'Approved with Conditions';
    command.conditionType = 'Protection Blocking';
    command.conditionDescription = 'Obtain signed customer confirmation';
    DealApprovalCommandService.complete(command);
    Deal_Approval__c completed = [
      SELECT Status__c, Authority_Snapshot__c
      FROM Deal_Approval__c
      WHERE Id = :step.Id
    ];
    Assert.areEqual('Completed', completed.Status__c);
    Assert.isNotNull(completed.Authority_Snapshot__c);
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Deal_Approval_Condition__c
        WHERE Approval__c = :step.Id
      ]
    );
    Assert.areEqual(
      'Approved with Conditions',
      [
        SELECT Status__c
        FROM Deal_Approval_Plan__c
        WHERE Deal__c = :deal.Id AND Current__c = TRUE
      ]
      .Status__c
    );
    Deal_Approval_Plan__c finalPlan = DealApprovalFinalisationGuard.assertReady(
      deal.Id,
      deal.Version_Number__c == null
        ? 0
        : Integer.valueOf(deal.Version_Number__c)
    );
    Assert.areEqual('Approved with Conditions', finalPlan.Status__c);
    try {
      DealApprovalCommandService.complete(command);
      Assert.fail('Expected stale command rejection.');
    } catch (DealApprovalCommandService.ApprovalCommandException expected) {
      Assert.isTrue(expected.getMessage().contains('changed'));
    }
  }

  @IsTest
  static void rejectsDecisionAboveAuthority() {
    Deal_Registration__c deal = deal(600000);
    DealApprovalPlanService.generate(new Set<Id>{ deal.Id });
    Assert.areEqual(
      0,
      [SELECT COUNT() FROM Deal_Approval__c WHERE Deal__c = :deal.Id]
    );
    try {
      DealApprovalFinalisationGuard.assertReady(
        deal.Id,
        deal.Version_Number__c == null
          ? 0
          : Integer.valueOf(deal.Version_Number__c)
      );
      Assert.fail('Expected pending plan rejection.');
    } catch (DealLifecycleException expected) {
      Assert.isTrue(expected.getMessage().contains('not final'));
    }
  }

  @IsTest
  static void rejectsMismatchedDealVersionAndMissingDecisions() {
    Deal_Registration__c deal = deal(100000);
    DealApprovalPlanService.generate(new Set<Id>{ deal.Id });
    Deal_Approval_Plan__c plan = [
      SELECT Id
      FROM Deal_Approval_Plan__c
      WHERE Deal__c = :deal.Id AND Current__c = TRUE
    ];
    plan.Status__c = 'Approved';
    update plan;
    try {
      DealApprovalFinalisationGuard.assertReady(deal.Id, 99);
      Assert.fail('Expected version mismatch.');
    } catch (DealLifecycleException expected) {
      Assert.isTrue(expected.getMessage().contains('different deal version'));
    }
    delete [SELECT Id FROM Deal_Approval__c WHERE Plan__c = :plan.Id];
    try {
      DealApprovalFinalisationGuard.assertReady(deal.Id, 0);
      Assert.fail('Expected missing decision rejection.');
    } catch (DealLifecycleException expected) {
      Assert.isTrue(expected.getMessage().contains('no decisions'));
    }
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
