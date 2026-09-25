/*
 * Tests DealReviewService's permission-gated decisioning: verifies that
 * view-only reviewer roles (e.g. Executive) can see the queue/detail but
 * are blocked from deciding, that Channel Manager can approve/reject, and
 * that a plain internal user with no reviewer permission set is blocked
 * entirely. Exercises the PartnerPermissionService rules those flows rely on.
 */
@IsTest
private class DealReviewServiceTest {
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
    System.assertNotEquals(
      null,
      updated.Protection_Start_Date__c,
      'Final approval should activate protection via DealProtectionCommandService.'
    );
    System.assertEquals(
      updated.Protection_Start_Date__c.addDays(30),
      updated.Protection_End_Date__c
    );
  }

  @IsTest
  static void protectionExtendedRoutesThroughTheGrantNotADirectDateWrite() {
    Deal_Registration__c deal = createSubmittedDeal();

    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      DealReviewDecisionDTO approveRequest = new DealReviewDecisionDTO();
      approveRequest.dealId = deal.Id;
      approveRequest.decision = 'Approved';
      approveRequest.approvalNotes = 'Approved by channel manager.';

      completeApprovalPlan(deal.Id);
      DealReviewService.processDecision(approveRequest);

      DealReviewDecisionDTO extendRequest = new DealReviewDecisionDTO();
      extendRequest.dealId = deal.Id;
      extendRequest.decision = 'Protection Extended';
      extendRequest.protectionExtensionDays = 15;

      DealReviewService.processDecision(extendRequest);
    }

    Deal_Protection_Grant__c grant = [
      SELECT End_Date__c, Extension_Count__c, Version_Number__c
      FROM Deal_Protection_Grant__c
      WHERE Deal__c = :deal.Id AND Current__c = TRUE
    ];
    Deal_Registration__c updated = [
      SELECT Protection_End_Date__c
      FROM Deal_Registration__c
      WHERE Id = :deal.Id
    ];

    System.assertEquals(
      1,
      grant.Extension_Count__c,
      'The grant, not a direct field write, should record the extension.'
    );
    System.assertEquals(
      grant.End_Date__c,
      updated.Protection_End_Date__c,
      'The deal projection should match the grant after extension.'
    );
  }

  @IsTest
  static void protectionExtendedFailsCleanlyWithNoActiveGrant() {
    Deal_Registration__c deal = createSubmittedDeal();

    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      DealReviewDecisionDTO extendRequest = new DealReviewDecisionDTO();
      extendRequest.dealId = deal.Id;
      extendRequest.decision = 'Protection Extended';
      extendRequest.protectionExtensionDays = 15;

      try {
        DealReviewService.processDecision(extendRequest);
        Assert.fail('Expected a deal with no active grant to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(
          expected.getMessage().contains('no active protection grant')
        );
      }
    }
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

  @IsTest
  static void channelManagerCanOverrideAttribution() {
    Deal_Registration__c deal = createSubmittedDeal();

    User channelManager = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      DealReviewService.overrideAttribution(
        deal.Id,
        DealAttributionEngine.CO_SELL
      );
    }

    Deal_Registration__c updated = [
      SELECT Attribution_Type__c
      FROM Deal_Registration__c
      WHERE Id = :deal.Id
    ];
    System.assertEquals(
      DealAttributionEngine.CO_SELL,
      updated.Attribution_Type__c
    );
  }

  @IsTest
  static void executiveCannotOverrideAttribution() {
    Deal_Registration__c deal = createSubmittedDeal();

    User executiveUser = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      executiveUser.Id,
      'PartnerSync_Executive_User'
    );

    System.runAs(executiveUser) {
      Boolean threw = false;
      try {
        DealReviewService.overrideAttribution(
          deal.Id,
          DealAttributionEngine.CO_SELL
        );
      } catch (PartnerSyncHandledException ex) {
        threw = true;
      }
      System.assertEquals(
        true,
        threw,
        'A view-only reviewer should not be able to override attribution.'
      );
    }
  }

  @IsTest
  static void channelManagerCannotOverrideAttributionWithInvalidValue() {
    Deal_Registration__c deal = createSubmittedDeal();

    User channelManager = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      Boolean threw = false;
      try {
        DealReviewService.overrideAttribution(deal.Id, 'Not A Real Value');
      } catch (PartnerSyncHandledException ex) {
        threw = true;
        System.assertEquals(
          'A valid attribution type is required.',
          ex.getMessage()
        );
      }
      System.assertEquals(
        true,
        threw,
        'An invalid attribution type should be rejected.'
      );
    }
  }

  private static void completeApprovalPlan(Id dealId) {
    Deal_Registration__c deal = [
      SELECT Estimated_Revenue__c
      FROM Deal_Registration__c
      WHERE Id = :dealId
    ];
    ApprovalPlanService.generate(
      'Deal_Registration__c',
      new Set<Id>{ dealId },
      new Map<Id, Decimal>{ dealId => deal.Estimated_Revenue__c },
      new Map<Id, String>{ dealId => 'Test Deal' },
      new Map<Id, Integer>{ dealId => 0 }
    );
    Approval__c approval = [
      SELECT Id, Version_Number__c
      FROM Approval__c
      WHERE
        Object_Name__c = 'Deal_Registration__c'
        AND Target_Record_Id__c = :dealId
        AND Plan__r.Current__c = TRUE
      LIMIT 1
    ];
    ApprovalCommand command = new ApprovalCommand();
    command.approvalId = approval.Id;
    command.expectedVersion = Integer.valueOf(approval.Version_Number__c);
    command.decision = 'Approved';
    ApprovalCommandService.complete(command);
  }
}
