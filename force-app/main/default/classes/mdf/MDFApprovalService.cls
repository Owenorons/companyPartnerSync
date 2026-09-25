/**
 * Enforces MDF review/decision rules: who may approve vs. reject, budget
 * ceilings on approval, and side effects (audit log, platform event) once
 * a decision is recorded. Sits alongside MDFService (submission) and
 * MDFDomain (field mapping/validation) as the write path for the review
 * step.
 */
public with sharing class MDFApprovalService {
  /**
   * Records an internal reviewer's approve/reject decision on an MDF
   * request: enforces the approve/reject permission (separately gated
   * so a reviewer can hold one without the other), validates the
   * decision payload, guards against re-deciding an already-decided
   * request, applies the decision, updates the record, and logs an
   * audit entry (plus a platform event on approval).
   *
   * @param request The decision (approve or reject) and its details.
   */
  public static void processDecision(MDFDecisionDTO request) {
    // Approve and reject are gated by separate permissions so a reviewer
    // can be granted one without the other (e.g. reject-only triage).
    if (request != null && request.decision == 'Approved') {
      PartnerPermissionService.assertCanApproveMdf();
    } else {
      PartnerPermissionService.assertCanRejectMdf();
    }

    MDFDomain.validateDecision(request);

    SecurityUtil.assertUpdateable(MDF_Request__c.SObjectType);
    for (
      Schema.SObjectField field : new List<Schema.SObjectField>{
        MDF_Request__c.Status__c,
        MDF_Request__c.Approval_Comments__c,
        MDF_Request__c.Approver__c
      }
    ) {
      SecurityUtil.assertFieldUpdateable(
        MDF_Request__c.SObjectType,
        field.getDescribe().getName()
      );
    }
    if (request.decision == 'Approved') {
      SecurityUtil.assertFieldUpdateable(
        MDF_Request__c.SObjectType,
        MDF_Request__c.Approved_Amount__c.getDescribe().getName()
      );
      SecurityUtil.assertUpdateable(Account.SObjectType);
      SecurityUtil.assertFieldUpdateable(
        Account.SObjectType,
        Account.MDF_Used__c.getDescribe().getName()
      );
    }

    // Roll back budget consumption even if a caller catches a later request
    // write failure (for example, a subscriber validation rule).
    Savepoint decisionSavepoint = Database.setSavepoint();
    try {
      processLockedDecision(request);
    } catch (Exception ex) {
      Database.rollback(decisionSavepoint);
      throw ex;
    } finally {
      Database.releaseSavepoint(decisionSavepoint);
    }
  }

  private static void processLockedDecision(MDFDecisionDTO request) {
    MDF_Request__c record = MDFSelector.selectForDecision(request.requestId);

    // Guards against re-deciding a request that was already approved/
    // rejected (e.g. a stale UI or double-submit), which would otherwise
    // double-count against the partner's MDF budget on re-approval.
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

    if (request.decision == 'Approved') {
      PlatformEventPublisherService.publish(
        'MDFApproved',
        record.Id,
        'MDF_Request__c',
        record.Partner_Account__c,
        'MDF request approved.',
        'Info'
      );
    }
  }

  private static void approve(MDF_Request__c record, MDFDecisionDTO request) {
    // The pre-approval chain (Approval_Step_Rule__mdt scoped to
    // MDF_Request__c) must be complete before the final decision - mirrors
    // RegistrationLifecycleCommandHandler's FINALISE_APPROVAL gating for
    // Deal. MDF_Request__c has no version field, so 0 is used as a constant
    // rather than building version-tracking infrastructure. This stays safe
    // even with MDFService.resubmitRequest()'s Needs Information -> Submitted
    // cycle (see ApprovalReturnConsumerService): every generate() call for
    // this object always passes the same constant 0, so there's nothing for
    // a real staleness check to catch either way.
    try {
      ApprovalFinalisationGuard.assertReady('MDF_Request__c', record.Id, 0);
    } catch (ApprovalFinalisationGuard.ApprovalPlanNotReadyException ex) {
      throw new PartnerSyncHandledException(ex.getMessage());
    }

    Account partner = MDFSelector.selectPartnerBudgetForApproval(
      record.Partner_Account__c
    );

    Decimal budget = partner.MDF_Annual_Budget__c == null
      ? 0
      : partner.MDF_Annual_Budget__c;
    Decimal used = partner.MDF_Used__c == null ? 0 : partner.MDF_Used__c;
    Decimal newUsed = used + request.approvedAmount;

    // Budget ceiling is a soft block: PartnerSync_Approval_Override lets a
    // senior reviewer approve past the annual budget for exceptional
    // cases, rather than requiring a budget increase first.
    if (newUsed > budget && !PartnerPermissionService.canOverrideMdfBudget()) {
      throw new PartnerSyncHandledException('Partner MDF budget exceeded.');
    }

    // Same soft-block, same override authority, for the industry-scoped
    // eligible ceiling computed at submission by MDFCalculationEngine. Null
    // Eligible_Amount__c means no calculation rule matched, so there's
    // nothing to enforce beyond the account-level budget above.
    if (
      record.Eligible_Amount__c != null &&
      request.approvedAmount > record.Eligible_Amount__c &&
      !PartnerPermissionService.canOverrideMdfBudget()
    ) {
      throw new PartnerSyncHandledException(
        'Approved amount exceeds the eligible amount for this industry/campaign.'
      );
    }

    SecurityUtil.assertUpdateable(Account.SObjectType);

    update SecurityUtil.stripForUpdate(
      new List<SObject>{ new Account(Id = partner.Id, MDF_Used__c = newUsed) }
    );

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
