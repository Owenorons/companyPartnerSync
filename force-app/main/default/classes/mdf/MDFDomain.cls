public with sharing class MDFDomain {
  public static void validateSubmit(MDFRequestDTO request) {
    if (request == null) {
      throw new PartnerSyncHandledException('MDF request is required.');
    }

    if (String.isBlank(request.requestType)) {
      throw new PartnerSyncHandledException('Request type is required.');
    }

    if (String.isBlank(request.campaignName)) {
      throw new PartnerSyncHandledException('Campaign name is required.');
    }

    if (request.requestedAmount == null || request.requestedAmount <= 0) {
      throw new PartnerSyncHandledException(
        'Requested amount must be greater than zero.'
      );
    }

    if (
      request.startDate != null &&
      request.endDate != null &&
      request.endDate < request.startDate
    ) {
      throw new PartnerSyncHandledException(
        'End date cannot be before start date.'
      );
    }
  }

  public static void validateDecision(MDFDecisionDTO request) {
    if (request == null || request.requestId == null) {
      throw new PartnerSyncHandledException('MDF decision request is invalid.');
    }

    if (request.decision != 'Approved' && request.decision != 'Rejected') {
      throw new PartnerSyncHandledException('Unsupported MDF decision.');
    }

    if (
      request.decision == 'Approved' &&
      (request.approvedAmount == null ||
      request.approvedAmount <= 0)
    ) {
      throw new PartnerSyncHandledException(
        'Approved amount must be greater than zero.'
      );
    }

    if (
      request.decision == 'Rejected' && String.isBlank(request.rejectionReason)
    ) {
      throw new PartnerSyncHandledException('Rejection reason is required.');
    }
  }

  public static MDF_Request__c buildRequest(
    MDFRequestDTO request,
    Id partnerAccountId,
    Id partnerContactId
  ) {
    validateSubmit(request);

    MDF_Request__c record = new MDF_Request__c();

    record.Partner_Account__c = partnerAccountId;
    record.Submitted_By__c = partnerContactId;

    record.Campaign_Type__c = request.requestType;
    record.Campaign_Name__c = request.campaignName;

    record.Requested_Amount__c = request.requestedAmount;
    record.Activity_Start_Date__c = request.startDate;
    record.Activity_End_Date__c = request.endDate;

    if (request.roiTarget != null) {
      record.Expected_Leads__c = request.roiTarget;
    }
    record.Status__c = 'Submitted';

    return record;
  }

  public static MDFListDTO toListDTO(MDF_Request__c record) {
    MDFListDTO dto = new MDFListDTO();

    dto.requestId = record.Id;
    dto.requestNumber = record.Name;

    dto.partnerName = record.Partner_Account__r == null
      ? null
      : record.Partner_Account__r.Name;

    dto.campaignName = record.Campaign_Name__c;
    dto.requestType = record.Campaign_Type__c;
    dto.requestedAmount = record.Requested_Amount__c;
    dto.approvedAmount = record.Approved_Amount__c;
    dto.status = record.Status__c;
    dto.startDate = record.Activity_Start_Date__c;
    dto.endDate = record.Activity_End_Date__c;

    return dto;
  }

  public static MDFBudgetDTO toBudgetDTO(Account account) {
    Decimal annual = account.MDF_Annual_Budget__c == null
      ? 0
      : account.MDF_Annual_Budget__c;
    Decimal used = account.MDF_Used__c == null ? 0 : account.MDF_Used__c;

    MDFBudgetDTO dto = new MDFBudgetDTO();
    dto.annualBudget = annual;
    dto.usedBudget = used;
    dto.remainingBudget = annual - used;

    return dto;
  }
}
