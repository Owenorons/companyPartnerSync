@IsTest
private class DealApprovalWorkspaceServiceTest {
  @IsTest
  static void permissionSetHolderSeesAndDecidesPendingStep() {
    Deal_Registration__c deal = pendingDeal(100000);

    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      List<DealApprovalStepListDTO> steps = DealApprovalWorkspaceService.getMyPendingSteps();
      Assert.areEqual(1, steps.size());
      Assert.areEqual(deal.Id, steps[0].dealId);

      DealApprovalStepDetailDTO detail = DealApprovalWorkspaceService.getStepDetail(
        steps[0].approvalId
      );
      Assert.isTrue(detail.canDecide);

      DealApprovalDecisionDTO request = new DealApprovalDecisionDTO();
      request.approvalId = steps[0].approvalId;
      request.decision = 'Approved';
      request.expectedVersion = detail.expectedVersion;
      DealApprovalWorkspaceService.decide(request);

      Assert.areEqual(
        0,
        DealApprovalWorkspaceService.getMyPendingSteps().size()
      );
    }
  }

  @IsTest
  static void nonHolderSeesEmptyQueueAndCannotDecide() {
    Deal_Registration__c deal = pendingDeal(100000);
    Id approvalId = [
      SELECT Id
      FROM Deal_Approval__c
      WHERE Deal__c = :deal.Id
      LIMIT 1
    ]
    .Id;

    User plainInternalUser = TestUserFactory.createInternalUser();

    System.runAs(plainInternalUser) {
      Assert.areEqual(
        0,
        DealApprovalWorkspaceService.getMyPendingSteps().size()
      );

      DealApprovalStepDetailDTO detail = DealApprovalWorkspaceService.getStepDetail(
        approvalId
      );
      Assert.isFalse(detail.canDecide);

      DealApprovalDecisionDTO request = new DealApprovalDecisionDTO();
      request.approvalId = approvalId;
      request.decision = 'Approved';
      request.expectedVersion = detail.expectedVersion;

      try {
        DealApprovalWorkspaceService.decide(request);
        Assert.fail('Expected authority rejection.');
      } catch (DealApprovalCommandService.ApprovalCommandException expected) {
        Assert.isTrue(expected.getMessage().contains('lacks authority'));
      }
    }
  }

  @IsTest
  static void nonInternalUserIsBlockedFromWorkspace() {
    Deal_Registration__c deal = pendingDeal(100000);

    Account partnerAccount = new Account(Name = 'Simulated Partner');
    insert partnerAccount;

    User partnerLikeUser = TestUserFactory.createInternalUser();
    PartnerAccessService.testPartnerAccountIdsByUser.put(
      partnerLikeUser.Id,
      partnerAccount.Id
    );

    System.runAs(partnerLikeUser) {
      try {
        DealApprovalWorkspaceService.getMyPendingSteps();
        Assert.fail('Expected a non-internal user to be blocked.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('permission'));
      }
    }
  }

  private static Deal_Registration__c pendingDeal(Decimal amount) {
    Deal_Registration__c deal = new Deal_Registration__c(
      Status__c = 'Under Review',
      Estimated_Revenue__c = amount
    );
    insert deal;
    DealApprovalPlanService.generate(new Set<Id>{ deal.Id });
    return deal;
  }
}
