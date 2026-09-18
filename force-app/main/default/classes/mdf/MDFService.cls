/**
 * Partner-facing MDF write/read path: submits new requests (with tenant
 * and permission gating) and lists the caller's own requests/budget.
 * Decisioning is handled separately by MDFApprovalService, which is
 * internal-reviewer-only.
 */
public with sharing class MDFService {
  /**
   * Submits a new MDF request for the running partner user: enforces
   * the MDF feature flag, submission permission, and (when the request
   * is tied to a Deal) partner access to that Deal, then inserts the
   * record and logs usage, an audit entry, and a platform event.
   *
   * @param request The MDF request details to submit.
   */
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

    UsageMetricService.log(
      partnerAccountId,
      UsageMetricService.METRIC_TYPE_MDF_REQUEST
    );

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

  /**
   * Returns the running partner user's own MDF requests.
   *
   * @return List of the caller's MDF requests as list-row DTOs.
   */
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

  /**
   * Returns the running partner user's MDF budget standing.
   *
   * @return The caller's annual/used/remaining MDF budget.
   */
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
