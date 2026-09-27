/**
 * Second of the two consumers PartnerSyncEventHandler dispatches a
 * PartnerSync_Event__e to (see AuditEventConsumerService for the other).
 * Translates a raw Event_Type__c into user-facing notification copy via the
 * lookup maps below; an event type missing from TITLE_BY_EVENT_TYPE is
 * silently skipped, since not every business event warrants a partner
 * notification.
 */
public with sharing class NotificationEventConsumerService {
  private static final Map<String, String> TITLE_BY_EVENT_TYPE = new Map<String, String>{
    'DealSubmitted' => 'Deal Submitted',
    'DealApproved' => 'Deal Approved',
    'MDFSubmitted' => 'MDF Request Submitted',
    'MDFApproved' => 'MDF Request Approved',
    'LeadAccepted' => 'Lead Accepted',
    'LeadConverted' => 'Lead Converted',
    'CertificationExpiringSoon' => 'Certification Expiring Soon',
    'CertificationExpired' => 'Certification Expired',
    'DealParticipantInvited' => 'Co-Sell Invitation',
    'DealParticipantInvitationAtRisk' => 'Co-Sell Invitation At Risk',
    'CoSellActivated' => 'Co-Sell Active',
    'DealParticipantAccepted' => 'Co-Sell Invitation Accepted',
    'DealParticipantDeclined' => 'Co-Sell Invitation Declined',
    'DealParticipantActivated' => 'Co-Sell Participant Active',
    'DealParticipantSuspended' => 'Co-Sell Participant Suspended',
    'DealParticipantResumed' => 'Co-Sell Participant Resumed',
    'DealParticipantRemoved' => 'Co-Sell Participant Removed',
    'DealParticipantRoleChanged' => 'Co-Sell Role Changed',
    'SharedProtectionRequested' => 'Shared Protection Requested',
    'SharedProtectionGranted' => 'Shared Protection Granted',
    'DealOwnershipTransferred' => 'Deal Ownership Transferred',
    'DealParticipantContributionRecorded' => 'Contribution Recorded',
    'DealParticipantContributionApproved' => 'Contribution Approved',
    'OpportunityLinkedToDeal' => 'Opportunity Linked',
    'OpportunityCreatedForDeal' => 'Opportunity Created',
    'OpportunityUnlinkedFromDeal' => 'Opportunity Unlinked',
    'PrimaryOpportunityChanged' => 'Primary Opportunity Changed',
    'SalesExecutionClosedWon' => 'Deal Closed Won',
    'SalesExecutionClosedLost' => 'Deal Closed Lost',
    'DealOpportunityOrphaned' => 'Opportunity Relationship Orphaned',
    'DealReapprovalRequested' => 'Reapproval Requested',
    'SalesExecutionReopened' => 'Sales Execution Reopened',
    'ImplementationCreated' => 'Implementation Created',
    'ImplementationStarted' => 'Implementation Started',
    'ImplementationBlocked' => 'Implementation Blocked',
    'ImplementationResumed' => 'Implementation Resumed',
    'ImplementationCompleted' => 'Implementation Completed',
    'ImplementationCancelled' => 'Implementation Cancelled',
    'CustomerSuccessHandoffRequested' => 'Customer Success Handoff Requested',
    'ImplementationHandoffSubmitted' => 'Handoff Submitted',
    'ImplementationHandoffAccepted' => 'Handoff Accepted',
    'ImplementationHandoffReturned' => 'Handoff Returned',
    'ImplementationMilestoneStarted' => 'Milestone Started',
    'ImplementationMilestoneCompleted' => 'Milestone Completed',
    'ImplementationMilestoneBlocked' => 'Milestone Blocked',
    'ImplementationEvidenceSubmitted' => 'Evidence Submitted',
    'ImplementationEvidenceAccepted' => 'Evidence Accepted',
    'ImplementationEvidenceRejected' => 'Evidence Rejected',
    'ImplementationIssueRaised' => 'Issue Raised',
    'ImplementationIssueEscalated' => 'Issue Escalated',
    'ImplementationIssueResolved' => 'Issue Resolved',
    'CustomerAcceptanceRequested' => 'Customer Acceptance Requested',
    'CustomerAcceptanceReceived' => 'Customer Acceptance Received',
    'CustomerAcceptanceRejected' => 'Customer Acceptance Rejected',
    'ImplementationParticipantAssigned' => 'Delivery Participant Assigned',
    'ImplementationParticipantRemoved' => 'Delivery Participant Removed'
  };

  private static final Map<String, String> MESSAGE_BY_EVENT_TYPE = new Map<String, String>{
    'DealSubmitted' => 'A new deal registration has been submitted for review.',
    'DealApproved' => 'Your deal registration has been approved.',
    'MDFSubmitted' => 'A new MDF request has been submitted for review.',
    'MDFApproved' => 'Your MDF request has been approved.',
    'LeadAccepted' => 'A partner has accepted an assigned lead.',
    'LeadConverted' => 'A lead has been converted to a deal registration.',
    'CertificationExpiringSoon' => 'A partner certification expires in 30 days.',
    'CertificationExpired' => 'A partner certification has expired.',
    'DealParticipantInvited' => 'You have been invited to co-sell on a deal.',
    'DealParticipantInvitationAtRisk' => 'A co-sell invitation is approaching its response deadline.',
    'CoSellActivated' => 'Co-sell participation became active on this deal.',
    'DealParticipantAccepted' => 'A co-sell participant accepted their invitation.',
    'DealParticipantDeclined' => 'A co-sell participant declined their invitation.',
    'DealParticipantActivated' => 'A co-sell participant was activated.',
    'DealParticipantSuspended' => 'A co-sell participant was suspended.',
    'DealParticipantResumed' => 'A suspended co-sell participant was resumed.',
    'DealParticipantRemoved' => 'A co-sell participant was removed from the deal.',
    'DealParticipantRoleChanged' => 'A co-sell participant\'s role was changed.',
    'SharedProtectionRequested' => 'Shared protection was requested for a co-sell participant.',
    'SharedProtectionGranted' => 'Shared protection was granted to a co-sell participant.',
    'DealOwnershipTransferred' => 'This deal\'s ownership was transferred to a new partner.',
    'DealParticipantContributionRecorded' => 'A co-sell participant contribution was recorded.',
    'DealParticipantContributionApproved' => 'A co-sell participant contribution was approved.',
    'OpportunityLinkedToDeal' => 'An opportunity was linked to this deal.',
    'OpportunityCreatedForDeal' => 'A new opportunity was created for this deal.',
    'OpportunityUnlinkedFromDeal' => 'An opportunity was unlinked from this deal.',
    'PrimaryOpportunityChanged' => 'This deal\'s primary opportunity relationship changed.',
    'SalesExecutionClosedWon' => 'This deal\'s primary opportunity closed won.',
    'SalesExecutionClosedLost' => 'This deal\'s primary opportunity closed lost.',
    'DealOpportunityOrphaned' => 'This deal\'s primary opportunity relationship is no longer accessible.',
    'DealReapprovalRequested' => 'A material change requires this deal to be reapproved.',
    'SalesExecutionReopened' => 'This deal\'s sales execution was reopened.',
    'ImplementationCreated' => 'An implementation was created for this deal.',
    'ImplementationStarted' => 'An implementation started.',
    'ImplementationBlocked' => 'An implementation was paused.',
    'ImplementationResumed' => 'A paused implementation resumed.',
    'ImplementationCompleted' => 'An implementation was completed.',
    'ImplementationCancelled' => 'An implementation was cancelled or superseded.',
    'CustomerSuccessHandoffRequested' => 'This deal is ready to hand off to Customer Success.',
    'ImplementationHandoffSubmitted' => 'A sales-to-delivery handoff was submitted.',
    'ImplementationHandoffAccepted' => 'A sales-to-delivery handoff was accepted.',
    'ImplementationHandoffReturned' => 'A sales-to-delivery handoff was returned for more information.',
    'ImplementationMilestoneStarted' => 'A delivery milestone started.',
    'ImplementationMilestoneCompleted' => 'A delivery milestone completed.',
    'ImplementationMilestoneBlocked' => 'A delivery milestone was blocked.',
    'ImplementationEvidenceSubmitted' => 'Implementation evidence was submitted.',
    'ImplementationEvidenceAccepted' => 'Implementation evidence was accepted.',
    'ImplementationEvidenceRejected' => 'Implementation evidence was rejected.',
    'ImplementationIssueRaised' => 'A delivery issue was raised on an implementation.',
    'ImplementationIssueEscalated' => 'A delivery issue was escalated.',
    'ImplementationIssueResolved' => 'A delivery issue was resolved.',
    'CustomerAcceptanceRequested' => 'Customer acceptance was requested.',
    'CustomerAcceptanceReceived' => 'Customer acceptance was received.',
    'CustomerAcceptanceRejected' => 'Customer acceptance was rejected.',
    'ImplementationParticipantAssigned' => 'A delivery participant was assigned to the implementation.',
    'ImplementationParticipantRemoved' => 'A delivery participant was removed from the implementation.'
  };

  private static final Map<String, String> NOTIFICATION_TYPE_BY_EVENT_TYPE = new Map<String, String>{
    'DealSubmitted' => 'Deal',
    'DealApproved' => 'Deal',
    'MDFSubmitted' => 'MDF',
    'MDFApproved' => 'MDF',
    'LeadAccepted' => 'Lead',
    'LeadConverted' => 'Lead',
    'CertificationExpiringSoon' => 'Training',
    'CertificationExpired' => 'Training',
    'DealParticipantInvited' => 'Deal',
    'DealParticipantInvitationAtRisk' => 'Deal',
    'DealParticipantAccepted' => 'Deal',
    'DealParticipantDeclined' => 'Deal',
    'DealParticipantActivated' => 'Deal',
    'DealParticipantSuspended' => 'Deal',
    'DealParticipantResumed' => 'Deal',
    'DealParticipantRemoved' => 'Deal',
    'DealParticipantRoleChanged' => 'Deal',
    'SharedProtectionRequested' => 'Deal',
    'SharedProtectionGranted' => 'Deal',
    'DealOwnershipTransferred' => 'Deal',
    'DealParticipantContributionRecorded' => 'Deal',
    'DealParticipantContributionApproved' => 'Deal',
    'OpportunityLinkedToDeal' => 'Deal',
    'OpportunityCreatedForDeal' => 'Deal',
    'OpportunityUnlinkedFromDeal' => 'Deal',
    'PrimaryOpportunityChanged' => 'Deal',
    'SalesExecutionClosedWon' => 'Deal',
    'SalesExecutionClosedLost' => 'Deal',
    'DealOpportunityOrphaned' => 'Deal',
    'DealReapprovalRequested' => 'Deal',
    'SalesExecutionReopened' => 'Deal',
    'ImplementationCreated' => 'Implementation',
    'ImplementationStarted' => 'Implementation',
    'ImplementationBlocked' => 'Implementation',
    'ImplementationResumed' => 'Implementation',
    'ImplementationCompleted' => 'Implementation',
    'ImplementationCancelled' => 'Implementation',
    'CustomerSuccessHandoffRequested' => 'Implementation',
    'ImplementationHandoffSubmitted' => 'Implementation',
    'ImplementationHandoffAccepted' => 'Implementation',
    'ImplementationHandoffReturned' => 'Implementation',
    'ImplementationMilestoneStarted' => 'Implementation',
    'ImplementationMilestoneCompleted' => 'Implementation',
    'ImplementationMilestoneBlocked' => 'Implementation',
    'ImplementationEvidenceSubmitted' => 'Implementation',
    'ImplementationEvidenceAccepted' => 'Implementation',
    'ImplementationEvidenceRejected' => 'Implementation',
    'ImplementationIssueRaised' => 'Implementation',
    'ImplementationIssueEscalated' => 'Implementation',
    'ImplementationIssueResolved' => 'Implementation',
    'CustomerAcceptanceRequested' => 'Implementation',
    'CustomerAcceptanceReceived' => 'Implementation',
    'CustomerAcceptanceRejected' => 'Implementation',
    'ImplementationParticipantAssigned' => 'Implementation',
    'ImplementationParticipantRemoved' => 'Implementation'
  };

  /**
   * Notifies the given recipients of a business event, if its event type
   * maps to notification copy. Event types not present in
   * TITLE_BY_EVENT_TYPE are silently skipped. Throws when the event type
   * does map to notification copy but no recipients were resolved.
   *
   * @param eventRecord The published platform event to notify recipients about.
   * @param recipients The users to deliver the notification to.
   */
  public static void notifyBusinessEvent(
    PartnerSync_Event__e eventRecord,
    List<User> recipients
  ) {
    String title = TITLE_BY_EVENT_TYPE.get(eventRecord.Event_Type__c);

    if (title == null) {
      return;
    }

    if (recipients == null || recipients.isEmpty())
      throw new PartnerSyncHandledException(
        'No active partner user was found for notification delivery.'
      );

    for (User recipient : recipients) {
      NotificationRequestDTO request = new NotificationRequestDTO();
      request.partnerAccountId = idOrNull(eventRecord.Partner_Account_Id__c);
      request.recipientUserId = recipient.Id;
      request.recipientContactId = recipient.ContactId;
      request.notificationType = NOTIFICATION_TYPE_BY_EVENT_TYPE.get(
        eventRecord.Event_Type__c
      );
      request.title = title;
      request.message = MESSAGE_BY_EVENT_TYPE.get(eventRecord.Event_Type__c);
      request.relatedObject = eventRecord.Object_Name__c;
      request.relatedRecordId = idOrNull(eventRecord.Record_Id__c);
      NotificationService.create(request);
    }
  }

  private static Id idOrNull(String value) {
    return String.isBlank(value) ? null : (Id) value;
  }
}
