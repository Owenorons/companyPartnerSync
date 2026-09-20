/*
 * Verifies MDFApprovalService's permission and budget rules: reviewers
 * can approve within budget, are blocked beyond it without the override
 * permission set, can exceed it with the override, and a Channel Manager
 * without the MDF reviewer permission cannot approve at all.
 */
@IsTest
private class MDFApprovalServiceTest {
  private static MDF_Request__c createSubmittedMdfRequest() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;

    MDF_Request__c request = PartnerSyncTestDataFactory.mdfRequest(
      partner.Id,
      contact.Id
    );
    insert request;

    return request;
  }

  @IsTest
  static void mdfReviewerCanApproveWithinBudget() {
    MDF_Request__c mdfRequest = createSubmittedMdfRequest();

    User mdfReviewer = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      mdfReviewer.Id,
      'PartnerSync_MDF_Reviewer'
    );

    MDFDecisionDTO request = new MDFDecisionDTO();
    request.requestId = mdfRequest.Id;
    request.decision = 'Approved';
    request.approvedAmount = 1000;
    request.decisionNotes = 'Approved within budget.';

    System.runAs(mdfReviewer) {
      MDFApprovalService.processDecision(request);
    }

    MDF_Request__c updated = [
      SELECT Status__c, Approved_Amount__c
      FROM MDF_Request__c
      WHERE Id = :mdfRequest.Id
    ];

    System.assertEquals('Approved', updated.Status__c);
    System.assertEquals(1000, updated.Approved_Amount__c);
  }

  @IsTest
  static void mdfReviewerBlockedWhenExceedingBudgetWithoutOverride() {
    MDF_Request__c mdfRequest = createSubmittedMdfRequest();

    User mdfReviewer = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      mdfReviewer.Id,
      'PartnerSync_MDF_Reviewer'
    );

    MDFDecisionDTO request = new MDFDecisionDTO();
    request.requestId = mdfRequest.Id;
    request.decision = 'Approved';
    request.approvedAmount = 20000;

    System.runAs(mdfReviewer) {
      System.assertEquals(
        false,
        PartnerPermissionService.canOverrideMdfBudget(),
        'The baseline MDF reviewer must not inherit the budget override.'
      );
      Boolean threw = false;

      try {
        MDFApprovalService.processDecision(request);
      } catch (PartnerSyncHandledException ex) {
        threw = true;
        System.assert(ex.getMessage().contains('budget'));
      }

      System.assertEquals(
        true,
        threw,
        'Approving beyond the remaining budget should fail without an override.'
      );
    }
  }

  @IsTest
  static void mdfReviewerWithOverrideCanExceedBudget() {
    MDF_Request__c mdfRequest = createSubmittedMdfRequest();

    User mdfReviewerWithOverride = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      mdfReviewerWithOverride.Id,
      'PartnerSync_MDF_Reviewer'
    );
    TestUserFactory.assignPermissionSet(
      mdfReviewerWithOverride.Id,
      'PartnerSync_Approval_Override'
    );

    MDFDecisionDTO request = new MDFDecisionDTO();
    request.requestId = mdfRequest.Id;
    request.decision = 'Approved';
    request.approvedAmount = 8000;

    System.runAs(mdfReviewerWithOverride) {
      MDFApprovalService.processDecision(request);
    }

    MDF_Request__c updated = [
      SELECT Status__c, Approved_Amount__c
      FROM MDF_Request__c
      WHERE Id = :mdfRequest.Id
    ];

    System.assertEquals('Approved', updated.Status__c);
    System.assertEquals(8000, updated.Approved_Amount__c);
  }

  @IsTest
  static void channelManagerWithoutMdfReviewerCannotApprove() {
    MDF_Request__c mdfRequest = createSubmittedMdfRequest();

    User channelManager = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    MDFDecisionDTO request = new MDFDecisionDTO();
    request.requestId = mdfRequest.Id;
    request.decision = 'Approved';
    request.approvedAmount = 1000;

    System.runAs(channelManager) {
      Boolean threw = false;

      try {
        MDFApprovalService.processDecision(request);
      } catch (PartnerSyncHandledException ex) {
        threw = true;
      }

      System.assertEquals(
        true,
        threw,
        'Channel Manager needs PartnerSync_MDF_Reviewer to approve MDF requests.'
      );
    }
  }

  @IsTest
  static void mdfReviewerCanRejectMdf() {
    MDF_Request__c mdfRequest = createSubmittedMdfRequest();

    User mdfReviewer = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      mdfReviewer.Id,
      'PartnerSync_MDF_Reviewer'
    );

    MDFDecisionDTO request = new MDFDecisionDTO();
    request.requestId = mdfRequest.Id;
    request.decision = 'Rejected';
    request.rejectionReason = 'Campaign does not meet criteria.';

    System.runAs(mdfReviewer) {
      MDFApprovalService.processDecision(request);
    }

    MDF_Request__c updated = [
      SELECT Status__c
      FROM MDF_Request__c
      WHERE Id = :mdfRequest.Id
    ];

    System.assertEquals('Rejected', updated.Status__c);
  }

  @IsTest
  static void repeatedDecisionCannotConsumeBudgetTwiceOrReverseApproval() {
    MDF_Request__c mdf = createSubmittedMdfRequest();
    User reviewer = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      reviewer.Id,
      'PartnerSync_MDF_Reviewer'
    );
    System.runAs(reviewer) {
      MDFDecisionDTO decision = approval(mdf.Id, 1000);
      MDFApprovalService.processDecision(decision);
      assertDecisionBlocked(decision, 'Only submitted');
      decision.decision = 'Rejected';
      decision.rejectionReason = 'Stale reviewer tab';
      assertDecisionBlocked(decision, 'Only submitted');
    }
    Assert.areEqual(
      3500,
      [SELECT MDF_Used__c FROM Account WHERE Id = :mdf.Partner_Account__c]
      .MDF_Used__c
    );
    Assert.areEqual(
      'Approved',
      [SELECT Status__c FROM MDF_Request__c WHERE Id = :mdf.Id].Status__c
    );
  }

  @IsTest
  static void separateRequestsConsumeTheLatestSharedBudget() {
    MDF_Request__c first = createSubmittedMdfRequest();
    MDF_Request__c second = PartnerSyncTestDataFactory.mdfRequest(
      first.Partner_Account__c,
      first.Submitted_By__c
    );
    insert second;
    User reviewer = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      reviewer.Id,
      'PartnerSync_MDF_Reviewer'
    );
    System.runAs(reviewer) {
      MDFApprovalService.processDecision(approval(first.Id, 5000));
      assertDecisionBlocked(approval(second.Id, 3000), 'budget exceeded');
      MDFApprovalService.processDecision(approval(second.Id, 2500));
    }
    Assert.areEqual(
      10000,
      [SELECT MDF_Used__c FROM Account WHERE Id = :first.Partner_Account__c]
      .MDF_Used__c
    );
    Assert.areEqual(
      'Approved',
      [SELECT Status__c FROM MDF_Request__c WHERE Id = :second.Id].Status__c
    );
  }

  @IsTest
  static void failedRequestWriteRollsBackBudgetEvenWhenCallerCatchesFailure() {
    MDF_Request__c mdf = createSubmittedMdfRequest();
    User reviewer = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      reviewer.Id,
      'PartnerSync_MDF_Reviewer'
    );
    System.runAs(reviewer) {
      MDFDecisionDTO decision = approval(mdf.Id, 1000);
      // Force the request write to fail after the account consumption update.
      decision.decisionNotes = 'x'.repeat(32769);
      try {
        MDFApprovalService.processDecision(decision);
        Assert.fail('Expected the oversized comment to fail DML.');
      } catch (DmlException expected) {
        Assert.areEqual(
          'STRING_TOO_LONG',
          String.valueOf(expected.getDmlStatusCode(0))
        );
      }
      Assert.areEqual(
        2500,
        [SELECT MDF_Used__c FROM Account WHERE Id = :mdf.Partner_Account__c]
        .MDF_Used__c
      );
      Assert.areEqual(
        'Submitted',
        [SELECT Status__c FROM MDF_Request__c WHERE Id = :mdf.Id].Status__c
      );
      decision.decisionNotes = 'Retry after correction';
      MDFApprovalService.processDecision(decision);
    }
    Assert.areEqual(
      3500,
      [SELECT MDF_Used__c FROM Account WHERE Id = :mdf.Partner_Account__c]
      .MDF_Used__c
    );
  }

  private static MDFDecisionDTO approval(Id requestId, Decimal amount) {
    MDFDecisionDTO decision = new MDFDecisionDTO();
    decision.requestId = requestId;
    decision.decision = 'Approved';
    decision.approvedAmount = amount;
    return decision;
  }

  private static void assertDecisionBlocked(
    MDFDecisionDTO decision,
    String message
  ) {
    try {
      MDFApprovalService.processDecision(decision);
      Assert.fail('Expected decision to be blocked.');
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(
        expected.getMessage().contains(message),
        expected.getMessage()
      );
    }
  }
}
