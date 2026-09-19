/*
 * Tests DealReviewService's permission-gated decisioning: verifies that
 * view-only reviewer roles (e.g. Executive) can see the queue/detail but
 * are blocked from deciding, that Channel Manager can approve/reject, and
 * that a plain internal user with no reviewer permission set is blocked
 * entirely. Exercises the PartnerPermissionService rules those flows rely on.
 */
@IsTest
private class DealReviewServiceTest {
  @IsTest
  static void expireProtectionUpdatesOnlyPastApprovedDeals() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Expiry Partner'
    );
    insert partner;
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Expiry Customer'
    );
    insert customer;
    Deal_Registration__c expired = PartnerSyncTestDataFactory.deal(
      customer.Id,
      partner.Id,
      null,
      null
    );
    expired.Status__c = 'Approved';
    expired.Protection_End_Date__c = Date.today().addDays(-1);
    insert expired;

    DealReviewService.expireProtection(expired.Id);
    Assert.areEqual(
      'Expired',
      [SELECT Status__c FROM Deal_Registration__c WHERE Id = :expired.Id]
      .Status__c
    );

    Deal_Registration__c active = PartnerSyncTestDataFactory.deal(
      customer.Id,
      partner.Id,
      null,
      null
    );
    active.Status__c = 'Approved';
    active.Protection_End_Date__c = Date.today().addDays(5);
    insert active;
    try {
      DealReviewService.expireProtection(active.Id);
      Assert.fail('Expected active protection to be retained.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('not past'));
    }
  }

  private static Deal_Registration__c createSubmittedDeal() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      partner.Id,
      null,
      null
    );
    deal.Customer_Name__c = 'Customer';
    insert deal;

    return deal;
  }

  @IsTest
  static void executiveCanViewQueueAndDetailButCannotApprove() {
    Deal_Registration__c deal = createSubmittedDeal();

    User executiveUser = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      executiveUser.Id,
      'PartnerSync_Executive_User'
    );

    System.runAs(executiveUser) {
      List<DealReviewListDTO> queue = DealReviewService.getReviewQueue();
      System.assertEquals(
        1,
        queue.size(),
        'Executive should be able to view the review queue.'
      );

      DealReviewDetailDTO detail = DealReviewService.getReviewDetail(deal.Id);
      System.assertEquals(false, detail.canApprove);
      System.assertEquals(false, detail.canReject);

      DealReviewDecisionDTO request = new DealReviewDecisionDTO();
      request.dealId = deal.Id;
      request.decision = 'Approved';
      request.approvalNotes = 'Looks good.';

      Boolean threw = false;

      try {
        DealReviewService.processDecision(request);
      } catch (PartnerSyncHandledException ex) {
        threw = true;
      }

      System.assertEquals(
        true,
        threw,
        'Executive should not be able to approve a deal.'
      );
    }
  }

  @IsTest
  static void channelManagerCanApproveDeal() {
    Deal_Registration__c deal = createSubmittedDeal();

    User channelManager = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      DealReviewDetailDTO detail = DealReviewService.getReviewDetail(deal.Id);
      System.assertEquals(true, detail.canApprove);
      System.assertEquals(true, detail.canReject);

      DealReviewDecisionDTO request = new DealReviewDecisionDTO();
      request.dealId = deal.Id;
      request.decision = 'Approved';
      request.approvalNotes = 'Approved by channel manager.';

      completeApprovalPlan(deal.Id);
      DealReviewService.processDecision(request);
    }

    Deal_Registration__c updated = [
      SELECT Status__c, Protection_Start_Date__c, Protection_End_Date__c
      FROM Deal_Registration__c
      WHERE Id = :deal.Id
    ];

    System.assertEquals('Approved', updated.Status__c);
    System.assertEquals(null, updated.Protection_Start_Date__c);
    System.assertEquals(null, updated.Protection_End_Date__c);
  }

  @IsTest
  static void channelManagerCanRejectDeal() {
    Deal_Registration__c deal = createSubmittedDeal();

    User channelManager = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      DealReviewDecisionDTO request = new DealReviewDecisionDTO();
      request.dealId = deal.Id;
      request.decision = 'Rejected';
      request.rejectionReason = 'Existing protected deal for this customer.';

      DealReviewService.processDecision(request);
    }

    Deal_Registration__c updated = [
      SELECT Status__c, Rejection_Reason__c
      FROM Deal_Registration__c
      WHERE Id = :deal.Id
    ];

    System.assertEquals('Rejected', updated.Status__c);
    System.assertEquals(
      'Existing protected deal for this customer.',
      updated.Rejection_Reason__c
    );
  }

  @IsTest
  static void channelManagerCannotApproveDealWithUnresolvedConflict() {
    Deal_Registration__c deal = createSubmittedDeal();
    deal.Status__c = 'Under Review';
    deal.Conflict_Status__c = 'Potential Conflict';
    update deal;

    User channelManager = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      DealReviewDecisionDTO request = new DealReviewDecisionDTO();
      request.dealId = deal.Id;
      request.decision = 'Approved';
      request.approvalNotes = 'Approved by channel manager.';

      Boolean threw = false;

      try {
        DealReviewService.processDecision(request);
      } catch (PartnerSyncHandledException ex) {
        threw = true;
      }

      System.assertEquals(
        true,
        threw,
        'A deal with an unresolved conflict should not be approvable.'
      );
    }

    Deal_Registration__c updated = [
      SELECT Status__c
      FROM Deal_Registration__c
      WHERE Id = :deal.Id
    ];

    System.assertEquals(
      'Under Review',
      updated.Status__c,
      'Status should be unchanged when approval is blocked by an unresolved conflict.'
    );
  }

  @IsTest
  static void channelManagerCanApproveDealAfterConflictResolved() {
    Deal_Registration__c deal = createSubmittedDeal();
    deal.Conflict_Status__c = 'Potential Conflict';
    update deal;

    User channelManager = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      DealReviewDecisionDTO resolveRequest = new DealReviewDecisionDTO();
      resolveRequest.dealId = deal.Id;
      resolveRequest.decision = 'Conflict Resolved';
      resolveRequest.conflictResolutionNotes = 'Confirmed no overlap.';

      DealReviewService.processDecision(resolveRequest);

      DealReviewDecisionDTO approveRequest = new DealReviewDecisionDTO();
      approveRequest.dealId = deal.Id;
      approveRequest.decision = 'Approved';
      approveRequest.approvalNotes = 'Approved by channel manager.';

      completeApprovalPlan(deal.Id);
      DealReviewService.processDecision(approveRequest);
    }

    Deal_Registration__c updated = [
      SELECT Status__c, Conflict_Status__c
      FROM Deal_Registration__c
      WHERE Id = :deal.Id
    ];

    System.assertEquals('Approved', updated.Status__c);
    System.assertEquals('Resolved', updated.Conflict_Status__c);
  }

  @IsTest
  static void plainInternalUserBlockedFromReviewQueue() {
    createSubmittedDeal();

    User plainInternalUser = TestUserFactory.createInternalUser();

    System.runAs(plainInternalUser) {
      Boolean threw = false;

      try {
        DealReviewService.getReviewQueue();
      } catch (PartnerSyncHandledException ex) {
        threw = true;
      }

      System.assertEquals(
        true,
        threw,
        'A plain internal user with no reviewer permission set should be blocked.'
      );
    }
  }

  private static void completeApprovalPlan(Id dealId) {
    DealApprovalPlanService.generate(new Set<Id>{ dealId });
    Deal_Approval__c approval = [
      SELECT Id, Version_Number__c
      FROM Deal_Approval__c
      WHERE Deal__c = :dealId AND Plan__r.Current__c = TRUE
      LIMIT 1
    ];
    DealApprovalCommand command = new DealApprovalCommand();
    command.approvalId = approval.Id;
    command.expectedVersion = Integer.valueOf(approval.Version_Number__c);
    command.decision = 'Approved';
    DealApprovalCommandService.complete(command);
  }
}
