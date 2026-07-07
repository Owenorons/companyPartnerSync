public with sharing class MDFService {
  public static void submitRequest(MDFRequestDTO request) {
    if (!TenantConfigService.isMdfEnabled()) {
      throw new PartnerSyncHandledException('MDF is disabled.');
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

    Account account = [
      SELECT MDF_Annual_Budget__c, MDF_Used__c
      FROM Account
      WHERE Id = :partnerAccountId
      LIMIT 1
    ];

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
