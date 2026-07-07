public with sharing class MDFApprovalService {
  public static void processDecision(MDFDecisionDTO request) {
    PartnerPermissionService.assertCanApproveMdf();

    MDFDomain.validateDecision(request);

    SecurityUtil.assertUpdateable(MDF_Request__c.SObjectType);

    MDF_Request__c record = MDFSelector.selectForInternalReview(
      request.requestId
    );

    if (record.Status__c != 'Submitted' && record.Status__c != 'Under Review') {
      throw new PartnerSyncHandledException(
        'Only submitted or under review MDF requests can be decided.'
      );
    }

    if (request.decision == 'Approved') {
      approve(record, request);
    } else {
      reject(record, request);
    }

    update SecurityUtil.stripForUpdate(new List<SObject>{ record });

    AuditLogRequestDTO audit = AuditFactory.createSuccess(
      'MDF_Request__c',
      record.Id,
      request.decision == 'Approved' ? 'Approve' : 'Reject'
    );

    audit.partnerAccountId = record.Partner_Account__c;

    AuditService.log(audit);
  }

  private static void approve(MDF_Request__c record, MDFDecisionDTO request) {
    Account partner = MDFSelector.selectPartnerBudget(
      record.Partner_Account__c
    );

    Decimal budget = partner.MDF_Annual_Budget__c == null
      ? 0
      : partner.MDF_Annual_Budget__c;
    Decimal used = partner.MDF_Used__c == null ? 0 : partner.MDF_Used__c;
    Decimal newUsed = used + request.approvedAmount;

    if (newUsed > budget) {
      throw new PartnerSyncHandledException('Partner MDF budget exceeded.');
    }

    SecurityUtil.assertUpdateable(Account.SObjectType);

    partner.MDF_Used__c = newUsed;

    update SecurityUtil.stripForUpdate(new List<SObject>{ partner });

    record.Status__c = 'Approved';
    record.Approved_Amount__c = request.approvedAmount;
    record.Approval_Comments__c = request.decisionNotes;
    record.Approver__c = UserInfo.getUserId();
  }

  private static void reject(MDF_Request__c record, MDFDecisionDTO request) {
    record.Status__c = 'Rejected';
    record.Approval_Comments__c = String.isBlank(request.decisionNotes)
      ? request.rejectionReason
      : request.decisionNotes +
        '\n\nRejection reason: ' +
        request.rejectionReason;
    record.Approver__c = UserInfo.getUserId();
  }
}
