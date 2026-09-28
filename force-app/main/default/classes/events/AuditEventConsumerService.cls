/**
 * One of two consumers PartnerSyncEventHandler fans a PartnerSync_Event__e
 * out to (the other being NotificationEventConsumerService). Event types not
 * present in AUDIT_ACTION_BY_EVENT_TYPE are deliberately ignored rather than
 * erroring, since not every business event that fires this platform event
 * needs an audit trail entry.
 */
public with sharing class AuditEventConsumerService {
  private static final Map<String, String> AUDIT_ACTION_BY_EVENT_TYPE = new Map<String, String>{
    'DealSubmitted' => 'Submit',
    'DealApproved' => 'Approve',
    'LeadAccepted' => 'Accept',
    'LeadConverted' => 'Convert',
    'DealParticipantInvited' => 'Invite Participant',
    'DealParticipantAccepted' => 'Accept Participation',
    'DealParticipantDeclined' => 'Decline Participation',
    'DealParticipantActivated' => 'Activate Participant',
    'DealParticipantSuspended' => 'Suspend Participant',
    'DealParticipantResumed' => 'Resume Participant',
    'DealParticipantRemoved' => 'Remove Participant',
    'DealParticipantRoleChanged' => 'Change Participant Role',
    'SharedProtectionRequested' => 'Request Shared Protection',
    'SharedProtectionGranted' => 'Grant Shared Protection',
    'DealOwnershipTransferred' => 'Transfer Deal Ownership',
    'OpportunityLinkedToDeal' => 'Link Opportunity',
    'OpportunityCreatedForDeal' => 'Create Opportunity',
    'OpportunityUnlinkedFromDeal' => 'Unlink Opportunity',
    'PrimaryOpportunityChanged' => 'Change Primary Opportunity',
    'SalesExecutionClosedWon' => 'Close Won',
    'SalesExecutionClosedLost' => 'Close Lost',
    'DealOpportunityOrphaned' => 'Flag Orphaned Opportunity',
    'DealReapprovalRequested' => 'Request Reapproval',
    'SalesExecutionReopened' => 'Reopen Sales Execution',
    'ImplementationCreated' => 'Create Implementation',
    'ImplementationStarted' => 'Start Implementation',
    'ImplementationBlocked' => 'Block Implementation',
    'ImplementationResumed' => 'Resume Implementation',
    'ImplementationCompleted' => 'Complete Implementation',
    'ImplementationCancelled' => 'Cancel Implementation',
    'CustomerSuccessHandoffRequested' => 'Request Customer Success Handoff',
    'ImplementationHandoffSubmitted' => 'Submit Handoff',
    'ImplementationHandoffAccepted' => 'Accept Handoff',
    'ImplementationHandoffReturned' => 'Return Handoff',
    'ImplementationMilestoneStarted' => 'Start Milestone',
    'ImplementationMilestoneCompleted' => 'Complete Milestone',
    'ImplementationMilestoneBlocked' => 'Block Milestone',
    'ImplementationEvidenceSubmitted' => 'Submit Evidence',
    'ImplementationEvidenceAccepted' => 'Accept Evidence',
    'ImplementationEvidenceRejected' => 'Reject Evidence',
    'ImplementationIssueRaised' => 'Raise Issue',
    'ImplementationIssueEscalated' => 'Escalate Issue',
    'ImplementationIssueResolved' => 'Resolve Issue',
    'CustomerAcceptanceRequested' => 'Request Customer Acceptance',
    'CustomerAcceptanceReceived' => 'Record Customer Acceptance',
    'CustomerAcceptanceRejected' => 'Reject Customer Acceptance',
    'ImplementationParticipantAssigned' => 'Assign Delivery Participant',
    'ImplementationParticipantRemoved' => 'Remove Delivery Participant',
    'DealRevenueImported' => 'Import Revenue',
    'DealRevenueUnmatched' => 'Flag Unmatched Revenue',
    'DealRevenueMatched' => 'Reconcile Revenue',
    'DealRevenueConfirmed' => 'Confirm Revenue',
    'DealRevenueAdjusted' => 'Adjust Revenue',
    'DealRevenueReversed' => 'Reverse Revenue',
    'RevenueAttributionCalculated' => 'Calculate Attribution',
    'RevenueAttributionOverridden' => 'Override Attribution',
    'RevenueAttributionReversed' => 'Reverse Attribution',
    'PartnerIncentiveEligible' => 'Evaluate Incentive Eligible',
    'PartnerIncentiveIneligible' => 'Evaluate Incentive Ineligible',
    'PartnerIncentiveCalculated' => 'Calculate Incentive',
    'PartnerIncentiveClaimSubmitted' => 'Submit Incentive Claim',
    'PartnerIncentiveApproved' => 'Approve Incentive Claim',
    'PartnerIncentiveRejected' => 'Reject Incentive Claim',
    'PartnerIncentivePaid' => 'Record Incentive Payment',
    'PartnerIncentivePaymentFailed' => 'Reverse Incentive Payment',
    'PartnerRevenueDisputeOpened' => 'Open Revenue Dispute',
    'PartnerRevenueDisputeResolved' => 'Resolve Revenue Dispute',
    'CustomerSuccessEngagementCreated' => 'Create Customer Success Engagement',
    'CustomerSuccessHandoffAccepted' => 'Accept Customer Success Handoff',
    'CustomerHealthChanged' => 'Change Customer Health',
    'CustomerRiskRaised' => 'Raise Customer Risk',
    'CustomerRiskResolved' => 'Resolve Customer Risk',
    'CustomerChurned' => 'Record Customer Churn',
    'CommercialEntitlementRecorded' => 'Record Commercial Entitlement',
    'CommercialEntitlementRenewed' => 'Renew Commercial Entitlement',
    'CommercialEntitlementCancelled' => 'Cancel Commercial Entitlement',
    'RenewalPartnerConfirmed' => 'Confirm Renewal Participation',
    'RenewalPartnerDeclined' => 'Decline Renewal Participation',
    'RenewalQualified' => 'Qualify Renewal',
    'RenewalReviewRequested' => 'Request Renewal Review',
    'RenewalApproved' => 'Approve Renewal',
    'RenewalWon' => 'Win Renewal',
    'RenewalLost' => 'Lose Renewal',
    'RenewalOpportunityCreated' => 'Create Renewal Opportunity',
    'ExpansionIdentified' => 'Identify Expansion',
    'ExpansionQualified' => 'Qualify Expansion',
    'ExpansionDealRequired' => 'Require Expansion Deal',
    'ExpansionDealCreated' => 'Create Expansion Deal',
    'ExpansionCompleted' => 'Complete Expansion',
    'PartnerReassignmentRequested' => 'Request Partner Reassignment',
    'PartnerReassigned' => 'Approve Partner Reassignment',
    'AIInteractionCompleted' => 'Complete AI Interaction',
    'AIInteractionBlocked' => 'Block AI Interaction',
    'AIRecommendationProposed' => 'Propose AI Recommendation',
    'AIRecommendationExecuted' => 'Execute AI Recommendation',
    'PortfolioSnapshotComputed' => 'Compute Portfolio Snapshot',
    'ExecutiveSnapshotComputed' => 'Compute Executive Snapshot'
  };

  /**
   * Writes an audit log entry for a business event, if its event type maps
   * to an audit action. Event types not present in
   * AUDIT_ACTION_BY_EVENT_TYPE are silently ignored.
   *
   * @param eventRecord The published platform event to audit.
   */
  public static void logBusinessEvent(PartnerSync_Event__e eventRecord) {
    String action = AUDIT_ACTION_BY_EVENT_TYPE.get(eventRecord.Event_Type__c);

    if (action == null) {
      return;
    }

    AuditLogRequestDTO audit = AuditFactory.createSuccess(
      eventRecord.Object_Name__c,
      idOrNull(eventRecord.Record_Id__c),
      action
    );

    audit.partnerAccountId = idOrNull(eventRecord.Partner_Account_Id__c);

    AuditService.log(audit);
  }

  private static Id idOrNull(String value) {
    return String.isBlank(value) ? null : (Id) value;
  }
}
