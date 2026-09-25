/**
 * Handles a partner's Accept/Reject decision on an already-assigned Lead.
 * Sits between LeadDistributionService (initial routing to a partner) and
 * LeadConversionService (turning an accepted lead into deal records) —
 * this class only ever moves a lead's status, it never creates Opportunity
 * or Deal Registration data.
 *
 * A thin, backward-compatible facade: processDecision() keeps its original
 * Lead-Id-keyed signature (so psPartnerLeads and any other existing caller
 * are unaffected), but resolves the lead's current active
 * Partner_Lead_Assignment__c and delegates the actual decision to
 * LeadAssignmentCommandService - the durable, versioned aggregate is now
 * the source of truth, not just Lead fields.
 */
public with sharing class LeadDecisionService {
  /**
   * Processes a partner's accept/reject decision on an assigned Lead,
   * updating its status and logging the action.
   *
   * @param request The lead decision request.
   */
  public static void processDecision(LeadDecisionRequestDTO request) {
    if (!TenantConfigService.isLeadsEnabled()) {
      throw new PartnerSyncHandledException('Lead distribution is disabled.');
    }

    LeadDistributionDomain.validateDecision(request);

    PartnerRecordAccessService.assertPartnerAccessToLead(request.leadId);

    Partner_Lead_Assignment__c assignment = PartnerLeadAssignmentSelector.selectActiveForLead(
      request.leadId
    );

    if (assignment == null) {
      throw new PartnerSyncHandledException(
        'Only assigned leads can be accepted or rejected.'
      );
    }

    LeadAssignmentCommand command = new LeadAssignmentCommand();
    command.assignmentId = assignment.Id;
    command.action = request.decision;
    command.expectedVersion = Integer.valueOf(assignment.Version_Number__c);
    command.reason = request.notes;

    LeadAssignmentCommandService.execute(command);

    LoggingService.info(
      'LeadDecisionService',
      'Lead decision processed. LeadId=' + request.leadId
    );
  }
}
