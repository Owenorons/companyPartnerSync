/**
 * Processes a decision (Accepted, Rejected) on a single Partner_Lead_Assignment__c record:
 * locks and validates the assignment, enforces that the acting user belongs to the assigned
 * partner account, records the decision, updates the Lead's projection fields, and logs/
 * publishes the same side effects LeadDecisionService always has.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class LeadAssignmentCommandService {
  /**
   * Executes the given lead assignment command.
   *
   * @param command The lead assignment decision command.
   */
  public static void execute(LeadAssignmentCommand command) {
    command.validate();

    Partner_Lead_Assignment__c assignment = PartnerLeadAssignmentSelector.selectForUpdate(
      command.assignmentId
    );

    assertAuthority(assignment);

    Integer version = assignment.Version_Number__c == null
      ? 0
      : Integer.valueOf(assignment.Version_Number__c);
    if (command.expectedVersion == null || command.expectedVersion != version) {
      throw new PartnerSyncHandledException(
        'The lead assignment changed. Refresh before retrying.'
      );
    }

    if (assignment.Status__c != 'Assigned') {
      throw new PartnerSyncHandledException(
        'Only an assigned lead can be accepted or rejected.'
      );
    }

    if (command.action != 'Accepted' && command.action != 'Rejected') {
      throw new PartnerSyncHandledException(
        'Unsupported lead assignment action: ' + command.action
      );
    }

    Datetime decidedOn = System.now();
    Lead leadUpdate = new Lead(Id = assignment.Lead__c);

    if (command.action == 'Accepted') {
      assignment.Status__c = 'Accepted';
      assignment.Accepted_On__c = decidedOn;
      leadUpdate.Lead_Distribution_Status__c = 'Accepted';
      leadUpdate.Accepted_Date__c = decidedOn;
    } else {
      assignment.Status__c = 'Rejected';
      assignment.Rejected_On__c = decidedOn;
      assignment.Rejection_Reason__c = command.reason;
      leadUpdate.Lead_Distribution_Status__c = 'Rejected';
      leadUpdate.Rejected_Date__c = decidedOn;
    }

    // Once decided, the assignment is no longer "active" - release the key
    // so a future distribution attempt (e.g. redistributing a rejected
    // lead) can create a new active assignment for this lead.
    assignment.Active_Assignment_Key__c = null;
    assignment.Version_Number__c = version + 1;

    Database.update(assignment, AccessLevel.SYSTEM_MODE);

    // Partners intentionally have read-only Lead CRUD. This command can only
    // mutate the two decision timestamps/status after record-scope access
    // and transition validation have both succeeded.
    Database.update(leadUpdate, AccessLevel.SYSTEM_MODE);

    LeadDistributionLogService.logAction(
      assignment.Lead__c,
      assignment.Partner_Account__c,
      assignment.Partner_Contact__c,
      command.action,
      assignment.Status__c,
      command.reason
    );

    // Only acceptance publishes a platform event — a rejection has no
    // downstream listeners (nothing else in the system reacts to it), so
    // firing an event for it would just be noise.
    if (command.action == 'Accepted') {
      PlatformEventPublisherService.publish(
        'LeadAccepted',
        assignment.Lead__c,
        'Lead',
        assignment.Partner_Account__c,
        'Partner accepted an assigned lead.',
        'Info'
      );
    }

    LoggingService.info(
      'LeadAssignmentCommandService',
      'Lead assignment decision processed. AssignmentId=' + assignment.Id
    );
  }

  private static void assertAuthority(Partner_Lead_Assignment__c assignment) {
    if (PartnerAccessService.isInternalUser()) {
      return;
    }
    if (
      assignment.Partner_Account__c !=
      PartnerAccessService.getCurrentPartnerAccountId()
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority for this lead assignment.'
      );
    }
  }
}
