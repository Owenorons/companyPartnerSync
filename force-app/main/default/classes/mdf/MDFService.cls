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

    // Security.stripInaccessible() (SecurityUtil.stripForCreate) returns new
    // SObject instances, not the same references passed in - inserting its
    // return value directly without capturing it would leave the original
    // record.Id null for everything below.
    List<SObject> sanitized = SecurityUtil.stripForCreate(
      new List<SObject>{ record }
    );

    insert sanitized;

    MDF_Request__c insertedRecord = (MDF_Request__c) sanitized[0];

    UsageMetricService.log(
      partnerAccountId,
      UsageMetricService.METRIC_TYPE_MDF_REQUEST
    );

    AuditLogRequestDTO audit = AuditFactory.createSuccess(
      'MDF_Request__c',
      insertedRecord.Id,
      'Submit'
    );

    audit.partnerAccountId = partnerAccountId;
    audit.partnerContactId = contact.Id;

    AuditService.log(audit);

    PlatformEventPublisherService.publish(
      'MDFSubmitted',
      insertedRecord.Id,
      'MDF_Request__c',
      partnerAccountId,
      'MDF request submitted for review.',
      'Info'
    );

    String targetLabel =
      insertedRecord.Name +
      (String.isBlank(insertedRecord.Campaign_Name__c)
        ? ''
        : ' — ' + insertedRecord.Campaign_Name__c);
    ApprovalPlanService.generate(
      'MDF_Request__c',
      new Set<Id>{ insertedRecord.Id },
      new Map<Id, Decimal>{
        insertedRecord.Id => insertedRecord.Requested_Amount__c
      },
      new Map<Id, String>{ insertedRecord.Id => targetLabel },
      new Map<Id, Integer>{ insertedRecord.Id => 0 }
    );

    notifyInternalReviewers(insertedRecord);
  }

  /**
   * Resubmits an MDF request that a pre-approval chain step returned for correction: regenerates
   * the approval plan and flips the request back to Submitted. The request must belong to the
   * running partner and currently be in Needs Information - set by
   * ApprovalReturnConsumerService when a chain step's decision is Returned.
   *
   * @param requestId Id of the MDF request to resubmit.
   */
  public static void resubmitRequest(Id requestId) {
    if (!TenantConfigService.isMdfEnabled()) {
      throw new PartnerSyncHandledException('MDF is disabled.');
    }

    if (!PartnerAccessService.canSubmitMDF()) {
      throw new PartnerSyncHandledException(
        'You do not have permission to submit MDF requests.'
      );
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();
    MDF_Request__c record = MDFSelector.selectForPartner(
      requestId,
      partnerAccountId
    );

    if (record.Status__c != 'Needs Information') {
      throw new PartnerSyncHandledException(
        'Only requests marked Needs Information can be resubmitted.'
      );
    }

    record.Status__c = 'Submitted';
    record.Return_Reason__c = null;
    Database.update(record, AccessLevel.SYSTEM_MODE);

    AuditLogRequestDTO audit = AuditFactory.createSuccess(
      'MDF_Request__c',
      record.Id,
      'Resubmit'
    );

    audit.partnerAccountId = partnerAccountId;

    AuditService.log(audit);

    String targetLabel =
      record.Name +
      (String.isBlank(record.Campaign_Name__c)
        ? ''
        : ' — ' + record.Campaign_Name__c);
    ApprovalPlanService.generate(
      'MDF_Request__c',
      new Set<Id>{ record.Id },
      new Map<Id, Decimal>{ record.Id => record.Requested_Amount__c },
      new Map<Id, String>{ record.Id => targetLabel },
      new Map<Id, Integer>{ record.Id => 0 }
    );

    PlatformEventPublisherService.publish(
      'MDFSubmitted',
      record.Id,
      'MDF_Request__c',
      partnerAccountId,
      'MDF request resubmitted for review.',
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
