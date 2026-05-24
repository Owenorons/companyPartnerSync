public with sharing class LeadDecisionService {
  public static void processDecision(LeadDecisionRequestDTO request) {
    if (!TenantConfigService.isLeadsEnabled()) {
      throw new PartnerSyncHandledException('Lead distribution is disabled.');
    }

    LeadDistributionDomain.validateDecision(request);

    SecurityUtil.assertUpdateable(Lead.SObjectType);

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    Lead lead = LeadDistributionSelector.selectPartnerLeadById(
      request.leadId,
      partnerAccountId
    );

    if (lead.Lead_Distribution_Status__c != 'Assigned') {
      throw new PartnerSyncHandledException(
        'Only assigned leads can be accepted or rejected.'
      );
    }

    if (request.decision == 'Accepted') {
      lead.Lead_Distribution_Status__c = 'Accepted';
      lead.Accepted_Date__c = System.now();
    }

    if (request.decision == 'Rejected') {
      lead.Lead_Distribution_Status__c = 'Rejected';
      lead.Rejected_Date__c = System.now();
    }

    update SecurityUtil.stripForUpdate(new List<SObject>{ lead });

    LeadDistributionLogService.logAction(
      lead.Id,
      lead.Partner_Account__c,
      lead.Partner_Contact__c,
      request.decision,
      lead.Lead_Distribution_Status__c,
      request.notes
    );

    LoggingService.info(
      'LeadDecisionService',
      'Lead decision processed. LeadId=' + lead.Id
    );
  }
}
