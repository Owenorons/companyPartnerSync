/*
 * Partner-facing MDF write/read path: submits new requests (with tenant
 * and permission gating) and lists the caller's own requests/budget.
 * Decisioning is handled separately by MDFApprovalService, which is
 * internal-reviewer-only.
 */
public with sharing class MDFService {
  public static void submitRequest(MDFRequestDTO request) {
    if (!TenantConfigService.isMdfEnabled()) {
      throw new PartnerSyncHandledException('MDF is disabled.');
    }

    if (!PartnerAccessService.canSubmitMDF()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to submit MDF requests.'
      );
    }

    SecurityUtil.assertCreateable(MDF_Request__c.SObjectType);

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();
    Contact contact = PartnerAccessService.getCurrentPartnerContact();

    if (request.relatedDealId != null) {
      PartnerRecordAccessService.assertPartnerAccessToDeal(
        request.relatedDealId
      );
    }

    MDF_Request__c record = MDFDomain.buildRequest(
      request,
      partnerAccountId,
      contact.Id
    );

    insert SecurityUtil.stripForCreate(new List<SObject>{ record });

    AuditLogRequestDTO audit = AuditFactory.createSuccess(
      'MDF_Request__c',
      record.Id,
      'Submit'
    );

    audit.partnerAccountId = partnerAccountId;
    audit.partnerContactId = contact.Id;

    AuditService.log(audit);

    PlatformEventPublisherService.publish(
      'MDFSubmitted',
      record.Id,
      'MDF_Request__c',
      partnerAccountId,
      'MDF request submitted for review.',
      'Info'
    );

    notifyInternalReviewers(record);
  }

  public static List<MDFListDTO> getMyRequests() {
    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    List<MDFListDTO> results = new List<MDFListDTO>();

    for (
      MDF_Request__c record : MDFSelector.selectMyRequests(partnerAccountId)
    ) {
      results.add(MDFDomain.toListDTO(record));
    }

    return results;
  }

  public static MDFBudgetDTO getMyBudget() {
    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();
    Account account = MDFSelector.selectPartnerBudget(partnerAccountId);

    return MDFDomain.toBudgetDTO(account);
  }

  private static void notifyInternalReviewers(MDF_Request__c record) {
    // Placeholder for reviewer routing later.
    LoggingService.info(
      'MDFService',
      'MDF request submitted and ready for review: ' + record.Id
    );
  }
}
