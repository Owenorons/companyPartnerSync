/*
 * Covers DealReviewStepController's thin wrapper behavior: a permitted
 * reviewer can list/load/work a pending step through the controller entry
 * points, while a handled exception from the service layer below surfaces
 * as an AuraHandledException rather than leaking internal exception types.
 */
@IsTest
private class DealReviewStepControllerTest {
  @IsTest
  static void permissionSetHolderListsLoadsAndWorksStepThroughController() {
    Deal_Registration__c deal = pendingDeal(1000);

    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      List<DealReviewStepListDTO> steps = DealReviewStepController.getMyPendingSteps();
      Assert.areEqual(1, steps.size());

      DealReviewStepDetailDTO detail = DealReviewStepController.getStepDetail(
        steps[0].reviewId
      );
      Assert.isTrue(detail.canDecide);

      DealReviewStepDecisionDTO request = new DealReviewStepDecisionDTO();
      request.reviewId = steps[0].reviewId;
      request.action = 'Start';
      request.expectedVersion = detail.expectedVersion;
      DealReviewStepController.decide(request);
    }

    Assert.areEqual(
      'In Progress',
      [
        SELECT Status__c
        FROM Deal_Review__c
        WHERE Deal__c = :deal.Id
      ]
      .Status__c
    );
  }

  @IsTest
  static void nonSpecificHolderGetsEmptyQueueButCannotWorkAStep() {
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
      // A plain internal user without the routed permission set gets an
      // empty queue, not an exception - only a step-level action needs the
      // specific routed authority (DealReviewCommandService.assertAuthority()).
      Assert.areEqual(0, DealReviewStepController.getMyPendingSteps().size());

      DealReviewStepDecisionDTO request = new DealReviewStepDecisionDTO();
      request.reviewId = reviewId;
      request.action = 'Start';
      request.expectedVersion = 0;

      Boolean threw = false;
      try {
        DealReviewStepController.decide(request);
      } catch (AuraHandledException ex) {
        threw = true;
      }

      Assert.isTrue(
        threw,
        'An unauthorized decide() call should surface as a handled exception.'
      );
    }
  }

  @IsTest
  static void nonInternalUserIsBlockedFromTheWorkspaceEntirely() {
    pendingDeal(1000);

    Account partnerAccount = new Account(Name = 'Simulated Partner');
    insert partnerAccount;

    User partnerLikeUser = TestUserFactory.createInternalUser();
    PartnerAccessService.testPartnerAccountIdsByUser.put(
      partnerLikeUser.Id,
      partnerAccount.Id
    );

    System.runAs(partnerLikeUser) {
      Boolean threw = false;

      try {
        DealReviewStepController.getMyPendingSteps();
      } catch (AuraHandledException ex) {
        threw = true;
      }

      Assert.isTrue(
        threw,
        'A non-internal user should be blocked from the workspace entirely.'
      );
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
