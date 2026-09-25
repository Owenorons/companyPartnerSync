@IsTest
private class ApprovalWorkspaceServiceTest {
  private static final String DEAL_OBJECT = 'Deal_Registration__c';

  @IsTest
  static void permissionSetHolderSeesAndDecidesPendingStep() {
    Deal_Registration__c deal = pendingDeal(100000);

    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      List<ApprovalStepListDTO> steps = ApprovalWorkspaceService.getMyPendingSteps();
      Assert.areEqual(1, steps.size());
      Assert.areEqual(deal.Id, steps[0].targetRecordId);
      Assert.areEqual(DEAL_OBJECT, steps[0].objectName);

      ApprovalStepDetailDTO detail = ApprovalWorkspaceService.getStepDetail(
        steps[0].approvalId
      );
      Assert.isTrue(detail.canDecide);

      ApprovalDecisionDTO request = new ApprovalDecisionDTO();
      request.approvalId = steps[0].approvalId;
      request.decision = 'Approved';
      request.expectedVersion = detail.expectedVersion;
      ApprovalWorkspaceService.decide(request);

      Assert.areEqual(0, ApprovalWorkspaceService.getMyPendingSteps().size());
    }
  }

  @IsTest
  static void nonHolderSeesEmptyQueueAndCannotDecide() {
    Deal_Registration__c deal = pendingDeal(100000);
    Id approvalId = [
      SELECT Id
      FROM Approval__c
      WHERE Object_Name__c = :DEAL_OBJECT AND Target_Record_Id__c = :deal.Id
      LIMIT 1
    ]
    .Id;

    User plainInternalUser = TestUserFactory.createInternalUser();

    System.runAs(plainInternalUser) {
      Assert.areEqual(0, ApprovalWorkspaceService.getMyPendingSteps().size());

      ApprovalStepDetailDTO detail = ApprovalWorkspaceService.getStepDetail(
        approvalId
      );
      Assert.isFalse(detail.canDecide);

      ApprovalDecisionDTO request = new ApprovalDecisionDTO();
      request.approvalId = approvalId;
      request.decision = 'Approved';
      request.expectedVersion = detail.expectedVersion;

      try {
        ApprovalWorkspaceService.decide(request);
        Assert.fail('Expected authority rejection.');
      } catch (ApprovalCommandService.ApprovalCommandException expected) {
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
        ApprovalWorkspaceService.getMyPendingSteps();
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
    ApprovalPlanService.generate(
      DEAL_OBJECT,
      new Set<Id>{ deal.Id },
      new Map<Id, Decimal>{ deal.Id => amount },
      new Map<Id, String>{ deal.Id => 'Test Deal' },
      new Map<Id, Integer>{ deal.Id => 0 }
    );
    return deal;
  }
}
