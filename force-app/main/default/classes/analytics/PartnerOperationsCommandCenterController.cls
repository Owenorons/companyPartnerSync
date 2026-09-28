/**
 * Aura controller surface for Sprint 44's Partner Operations Command
 * Center: a single counts-only "needs attention" summary across every
 * internal workbench built in a prior sprint. Each count matches the
 * exact filter criteria the corresponding workbench controller method
 * already uses (CustomerSuccessController.getPendingHandoffs() etc.), so
 * this summary's numbers always agree with what those workbenches
 * actually show - re-implemented here as COUNT()-only queries for a
 * genuinely different (summary, not row-list) purpose, never a
 * duplicated data grid. Internal-only; no new permission - a count
 * summary of queues any internal user can already reach individually.
 */
public with sharing class PartnerOperationsCommandCenterController {
  /**
   * Loads the cross-domain operations summary.
   *
   * @return Counts across every "needs attention" queue this org tracks.
   */
  @AuraEnabled(cacheable=true)
  public static OperationsSummaryDTO getOperationsSummary() {
    try {
      PartnerAccessService.assertInternalUser();

      OperationsSummaryDTO summary = new OperationsSummaryDTO();
      summary.pendingHandoffCount = [
        SELECT COUNT()
        FROM Customer_Success_Engagement__c
        WHERE Status__c = 'Pending Handoff'
        WITH SYSTEM_MODE
      ];
      summary.atRiskEngagementCount = [
        SELECT COUNT()
        FROM Customer_Success_Engagement__c
        WHERE Health_Status__c IN ('At Risk', 'Critical')
        WITH SYSTEM_MODE
      ];
      summary.renewalsDueCount = [
        SELECT COUNT()
        FROM Partner_Renewal__c
        WHERE
          Status__c IN ('Partner Confirmed', 'Qualification', 'Review Required')
        WITH SYSTEM_MODE
      ];
      summary.partnerConfirmationRequiredCount = [
        SELECT COUNT()
        FROM Partner_Renewal__c
        WHERE Status__c = 'Partner Confirmation Required'
        WITH SYSTEM_MODE
      ];
      summary.openExpansionCount = [
        SELECT COUNT()
        FROM Partner_Expansion__c
        WHERE Status__c NOT IN ('Completed', 'Cancelled')
        WITH SYSTEM_MODE
      ];
      summary.pendingReassignmentCount = [
        SELECT COUNT()
        FROM Partner_Reassignment__c
        WHERE Status__c = 'Requested'
        WITH SYSTEM_MODE
      ];
      summary.openDisputeCount = [
        SELECT COUNT()
        FROM Partner_Revenue_Dispute__c
        WHERE Status__c IN ('Open', 'Under Review')
        WITH SYSTEM_MODE
      ];
      summary.proposedRecommendationCount = [
        SELECT COUNT()
        FROM AI_Recommendation__c
        WHERE Status__c = 'Proposed'
        WITH SYSTEM_MODE
      ];
      return summary;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerOperationsCommandCenterController',
        'Unable to load the operations summary.',
        'Unable to load the operations summary.',
        ex
      );
    }
  }
}
