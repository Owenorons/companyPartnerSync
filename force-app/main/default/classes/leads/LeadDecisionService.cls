/*
 * Handles a partner's Accept/Reject decision on an already-assigned Lead.
 * Sits between LeadDistributionService (initial routing to a partner) and
 * LeadConversionService (turning an accepted lead into deal records) —
 * this class only ever moves a lead's status, it never creates Opportunity
 * or Deal Registration data.
 */
public with sharing class LeadDecisionService {
  public static void processDecision(LeadDecisionRequestDTO request) {
    if (!TenantConfigService.isLeadsEnabled()) {
      throw new PartnerSyncHandledException('Lead distribution is disabled.');
    }

    LeadDistributionDomain.validateDecision(request);

    PartnerRecordAccessService.assertPartnerAccessToLead(request.leadId);

    Lead lead = LeadDistributionSelector.selectInternalLead(request.leadId);

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

    // Partners intentionally have read-only Lead CRUD. This command can only
    // mutate the two decision timestamps/status after record-scope access and
    // transition validation have both succeeded.
    Database.update(lead, AccessLevel.SYSTEM_MODE);

    LeadDistributionLogService.logAction(
      lead.Id,
      lead.Partner_Account__c,
      lead.Partner_Contact__c,
      request.decision,
      lead.Lead_Distribution_Status__c,
      request.notes
    );

    // Only acceptance publishes a platform event — a rejection has no
    // downstream listeners (nothing else in the system reacts to it), so
    // firing an event for it would just be noise.
    if (request.decision == 'Accepted') {
      PlatformEventPublisherService.publish(
        'LeadAccepted',
        lead.Id,
        'Lead',
        lead.Partner_Account__c,
        'Partner accepted an assigned lead.',
        'Info'
      );
    }

    LoggingService.info(
      'LeadDecisionService',
      'Lead decision processed. LeadId=' + lead.Id
    );
  }
}
