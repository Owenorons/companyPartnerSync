/**
 * Domain layer for the assignment/decision half of the lead lifecycle:
 * validates assignment and accept/reject requests, and maps a Lead to its
 * partner-facing DTO. LeadConversionDomain is the counterpart for the later
 * step of turning an accepted lead into an Opportunity/Deal Registration.
 */
public with sharing class LeadDistributionDomain {
  /**
   * Validates that a lead assignment request carries the fields required to
   * proceed, throwing if any are missing.
   *
   * @param request The lead assignment request to validate.
   */
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

  /**
   * Validates that a lead decision request carries a lead Id and a
   * supported decision value, throwing if not.
   *
   * @param request The lead decision request to validate.
   */
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

  /**
   * Maps a Lead record to its partner-facing distribution DTO.
   *
   * @param lead The Lead record to map.
   * @return The mapped lead distribution DTO.
   */
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
