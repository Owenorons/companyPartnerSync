public with sharing class DealRegistrationDomain {
  public static void validate(DealRegistrationRequestDTO request) {
    if (request == null) {
      throw new PartnerSyncHandledException(
        'Deal registration request is required.'
      );
    }

    if (request.opportunityId == null) {
      throw new PartnerSyncHandledException('Opportunity Id is required.');
    }

    if (request.estimatedRevenue == null) {
      throw new PartnerSyncHandledException('Estimated revenue is required.');
    }
  }

  public static Deal_Registration__c buildRecord(
    Opportunity opportunity,
    DealRegistrationRequestDTO request
  ) {
    Deal_Registration__c record = new Deal_Registration__c();

    record.Opportunity__c = opportunity.Id;

    record.Customer_Account__c = opportunity.AccountId;

    record.Partner_Account__c = opportunity.Partner_Account__c;

    record.Partner_Contact__c = opportunity.Partner_Contact__c;

    record.Status__c = 'Submitted';

    record.Conflict_Status__c = 'Pending Analysis';

    record.Business_Problem__c = request.businessProblem;

    record.Proposed_Solution__c = request.proposedSolution;

    record.Estimated_Revenue__c = request.estimatedRevenue;

    record.Estimated_Close_Date__c = request.estimatedCloseDate;

    record.Implementation_Timeline__c = request.implementationTimeline;

    record.Submitted_On__c = System.now();

    record.Notes__c = request.notes;

    return record;
  }

  public static DealRegistrationResultDTO toDTO(Deal_Registration__c record) {
    DealRegistrationResultDTO dto = new DealRegistrationResultDTO();

    dto.dealRegistrationId = record.Id;

    dto.dealRegistrationNumber = record.Name;

    dto.status = record.Status__c;

    dto.conflictStatus = record.Conflict_Status__c;

    return dto;
  }

  public static DealRegistrationListDTO toListDTO(Deal_Registration__c record) {
    DealRegistrationListDTO dto = new DealRegistrationListDTO();

    dto.dealId = record.Id;
    dto.dealNumber = record.Name;

    dto.customerName = record.Customer_Account__r.Name;

    dto.partnerName = record.Partner_Account__r.Name;

    dto.dealValue = record.Estimated_Revenue__c;

    dto.stage = record.Opportunity__r.StageName;

    dto.status = record.Status__c;

    dto.conflictStatus = record.Conflict_Status__c;

    dto.protectionEndDate = record.Protection_End_Date__c;

    dto.createdDate = record.CreatedDate;

    return dto;
  }
}
