public with sharing class LeadDistributionDomain {
  public static void validateAssignment(LeadAssignmentRequestDTO request) {
    if (request == null) {
      throw new PartnerSyncHandledException(
        'Lead assignment request is required.'
      );
    }

    if (request.leadId == null) {
      throw new PartnerSyncHandledException('Lead Id is required.');
    }

    if (request.partnerAccountId == null) {
      throw new PartnerSyncHandledException('Partner Account is required.');
    }
  }

  public static void validateDecision(LeadDecisionRequestDTO request) {
    if (request == null || request.leadId == null) {
      throw new PartnerSyncHandledException(
        'Lead decision request is invalid.'
      );
    }

    if (request.decision != 'Accepted' && request.decision != 'Rejected') {
      throw new PartnerSyncHandledException('Unsupported lead decision.');
    }
  }

  public static LeadDistributionDTO toDTO(Lead lead) {
    LeadDistributionDTO dto = new LeadDistributionDTO();

    dto.leadId = lead.Id;
    dto.leadName = lead.Name;
    dto.company = lead.Company;
    dto.email = lead.Email;
    dto.phone = lead.Phone;
    dto.status = lead.Lead_Distribution_Status__c;
    dto.assignedDate = lead.Assigned_Date__c;
    dto.slaDeadline = lead.SLA_Deadline__c;

    return dto;
  }
}
