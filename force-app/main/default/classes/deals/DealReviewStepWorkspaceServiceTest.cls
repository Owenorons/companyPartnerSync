@IsTest
private class DealReviewStepWorkspaceServiceTest {
  @IsTest
  static void permissionSetHolderSeesAndWorksPendingStep() {
    Deal_Registration__c deal = pendingDeal(1000);

    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      List<DealReviewStepListDTO> steps = DealReviewStepWorkspaceService.getMyPendingSteps();
      Assert.areEqual(1, steps.size());
      Assert.areEqual(deal.Id, steps[0].dealId);
      Assert.areEqual('Channel_Review', steps[0].reviewKey);
      Assert.isFalse(steps[0].needsReassignment);

      DealReviewStepDetailDTO detail = DealReviewStepWorkspaceService.getStepDetail(
        steps[0].reviewId
      );
      Assert.isTrue(detail.canDecide);

      DealReviewStepDecisionDTO request = new DealReviewStepDecisionDTO();
      request.reviewId = steps[0].reviewId;
      request.action = 'Start';
      request.expectedVersion = detail.expectedVersion;
      DealReviewStepWorkspaceService.decide(request);

      List<DealReviewStepListDTO> afterStart = DealReviewStepWorkspaceService.getMyPendingSteps();
      Assert.areEqual(1, afterStart.size());
      Assert.areEqual('In Progress', afterStart[0].status);
    }
  }

  @IsTest
  static void nonHolderSeesEmptyQueueAndCannotWorkStep() {
    Deal_Registration__c deal = pendingDeal(1000);
    Id reviewId = [
      SELECT Id
      FROM Deal_Review__c
      WHERE Deal__c = :deal.Id
      LIMIT 1
    ]
    .Id;

    User plainInternalUser = TestUserFactory.createInternalUser();

    System.runAs(plainInternalUser) {
      Assert.areEqual(
        0,
        DealReviewStepWorkspaceService.getMyPendingSteps().size()
      );

      DealReviewStepDetailDTO detail = DealReviewStepWorkspaceService.getStepDetail(
        reviewId
      );
      Assert.isFalse(detail.canDecide);
      Assert.isFalse(detail.canReassign);

      DealReviewStepDecisionDTO request = new DealReviewStepDecisionDTO();
      request.reviewId = reviewId;
      request.action = 'Start';
      request.expectedVersion = detail.expectedVersion;

      try {
        DealReviewStepWorkspaceService.decide(request);
        Assert.fail('Expected authority rejection.');
      } catch (DealReviewCommandService.DealReviewCommandException expected) {
        Assert.isTrue(expected.getMessage().contains('lacks authority'));
      }
    }
  }

  @IsTest
  static void routingFailedStepIsSurfacedToReviewManagersForReassignment() {
    Deal_Registration__c deal = pendingDeal(1000);
    Deal_Review__c review = [
      SELECT Id, Version_Number__c
      FROM Deal_Review__c
      WHERE Deal__c = :deal.Id
      LIMIT 1
    ];
    review.Assigned_To__c = null;
    review.Approver_Permission_Set__c = null;
    review.Status__c = 'Routing Failed';
    update review;

    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      List<DealReviewStepListDTO> steps = DealReviewStepWorkspaceService.getMyPendingSteps();
      Assert.areEqual(1, steps.size());
      Assert.isTrue(steps[0].needsReassignment);

      DealReviewStepDetailDTO detail = DealReviewStepWorkspaceService.getStepDetail(
        review.Id
      );
      Assert.isFalse(detail.canDecide);
      Assert.isTrue(detail.canReassign);

      DealReviewStepDecisionDTO request = new DealReviewStepDecisionDTO();
      request.reviewId = review.Id;
      request.action = 'Reassign';
      request.assigneeId = channelManager.Id;
      request.expectedVersion = detail.expectedVersion;
      DealReviewStepWorkspaceService.decide(request);
    }

    Assert.areEqual(
      channelManager.Id,
      [SELECT Assigned_To__c FROM Deal_Review__c WHERE Id = :review.Id]
      .Assigned_To__c
    );
  }

  @IsTest
  static void nonInternalUserIsBlockedFromWorkspace() {
    pendingDeal(1000);

    Account partnerAccount = new Account(Name = 'Simulated Partner');
    insert partnerAccount;

    User partnerLikeUser = TestUserFactory.createInternalUser();
    PartnerAccessService.testPartnerAccountIdsByUser.put(
      partnerLikeUser.Id,
      partnerAccount.Id
    );

    System.runAs(partnerLikeUser) {
      try {
        DealReviewStepWorkspaceService.getMyPendingSteps();
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
    DealReviewPlanService.generate(new Set<Id>{ deal.Id });
    return deal;
  }
}
