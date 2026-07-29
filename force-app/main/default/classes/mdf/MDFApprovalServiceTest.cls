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
    request.approvedAmount = 8000;

    System.runAs(mdfReviewer) {
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
}
