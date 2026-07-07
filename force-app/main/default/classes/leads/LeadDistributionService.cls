public with sharing class LeadDistributionService {
  public static void assignLeadToPartner(LeadAssignmentRequestDTO request) {
    if (!TenantConfigService.isLeadsEnabled()) {
      throw new PartnerSyncHandledException('Lead distribution is disabled.');
    }

    PartnerAccessService.assertInternalUser();

    LeadDistributionDomain.validateAssignment(request);

    SecurityUtil.assertUpdateable(Lead.SObjectType);

    validatePartnerAccount(request.partnerAccountId);

    if (request.partnerContactId != null) {
      validatePartnerContact(
        request.partnerContactId,
        request.partnerAccountId
      );
    }

    if (request.customerAccountId != null) {
      CustomerAccountSelector.selectCustomerAccountById(
        request.customerAccountId
      );
    }

    Lead lead = LeadDistributionSelector.selectInternalLead(request.leadId);

    lead.Partner_Account__c = request.partnerAccountId;
    lead.Partner_Contact__c = request.partnerContactId;
    lead.Customer_Account__c = request.customerAccountId;
    lead.Lead_Distribution_Status__c = 'Assigned';
    lead.Assigned_Date__c = System.now();

    Integer slaHours = request.slaHoursOverride != null
      ? request.slaHoursOverride
      : TenantConfigService.getLeadSlaHours();

    lead.Response_SLA_Hours__c = slaHours;
    lead.SLA_Deadline__c = System.now().addHours(slaHours);

    update SecurityUtil.stripForUpdate(new List<SObject>{ lead });

    LeadDistributionLogService.logAction(
      lead.Id,
      request.partnerAccountId,
      request.partnerContactId,
      'Assigned',
      'Assigned',
      request.notes
    );

    LoggingService.info(
      'LeadDistributionService',
      'Lead assigned to partner. LeadId=' + lead.Id
    );
  }

  public static List<LeadDistributionDTO> getMyLeads() {
    if (!TenantConfigService.isLeadsEnabled()) {
      throw new PartnerSyncHandledException('Lead distribution is disabled.');
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    List<LeadDistributionDTO> results = new List<LeadDistributionDTO>();

    for (
      Lead lead : LeadDistributionSelector.selectAssignedLeadsByPartner(
        partnerAccountId
      )
    ) {
      results.add(LeadDistributionDomain.toDTO(lead));
    }

    return results;
  }

  private static void validatePartnerAccount(Id partnerAccountId) {
    LeadDistributionSelector.selectActivePartnerAccount(partnerAccountId);
  }

  private static void validatePartnerContact(
    Id contactId,
    Id partnerAccountId
  ) {
    LeadDistributionSelector.selectPartnerContact(contactId, partnerAccountId);
  }
}
