/**
 * Executes Implementation_Evidence__c commands: submit, review. Mirrors
 * PartnerDocumentService's shape closely (the direct precedent) - submit
 * takes a ContentDocumentId already uploaded via the standard Salesforce
 * Files uploader, no new upload plumbing needed.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ImplementationEvidenceCommandService {
  private static final String SUBMIT_PERMISSION = 'PartnerSync_Submit_Implementation_Evidence';
  private static final String REVIEW_PERMISSION = 'PartnerSync_Review_Implementation_Evidence';

  /**
   * Submits a new evidence record. Internal users may always submit;
   * external/partner users need PartnerSync_Submit_Implementation_Evidence.
   *
   * @param command implementationId + evidence fields.
   * @return The inserted evidence record.
   */
  public static Implementation_Evidence__c submit(
    ImplementationEvidenceCommand command
  ) {
    if (
      !PartnerAccessService.isInternalUser() &&
      !DealLifecyclePermissionService.hasPermission(SUBMIT_PERMISSION)
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to submit implementation evidence.'
      );
    }
    if (
      command.implementationId == null ||
      String.isBlank(command.evidenceType) ||
      String.isBlank(command.contentDocumentId)
    ) {
      throw new PartnerSyncHandledException(
        'An implementation, evidence type, and content document are required.'
      );
    }

    Implementation_Evidence__c evidence = new Implementation_Evidence__c(
      Implementation__c = command.implementationId,
      Milestone__c = command.milestoneId,
      Evidence_Type__c = command.evidenceType,
      Status__c = 'Submitted',
      ContentDocumentId__c = command.contentDocumentId,
      Submitted_By__c = UserInfo.getUserId(),
      Submitted_On__c = System.now(),
      Description__c = command.description,
      Partner_Visible__c = command.partnerVisible == true,
      Customer_Visible__c = command.customerVisible == true
    );
    Database.insert(evidence, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'ImplementationEvidenceSubmitted',
      command.implementationId,
      'Deal_Implementation__c',
      null,
      'Implementation evidence was submitted.',
      'Info'
    );

    return evidence;
  }

  /**
   * Reviews a submitted evidence record (Accept/Reject). Accepting
   * re-checks the linked milestone and completes it if it's currently In
   * Progress and has no other blocking guard.
   *
   * @param command evidenceId + outcome (Accepted/Rejected) + reason.
   */
  public static void review(ImplementationEvidenceCommand command) {
    PartnerAccessService.assertInternalUser();
    if (!DealLifecyclePermissionService.hasPermission(REVIEW_PERMISSION)) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to review implementation evidence.'
      );
    }
    if (command.evidenceId == null) {
      throw new PartnerSyncHandledException(
        'Evidence is required for this command.'
      );
    }
    if (command.outcome != 'Accepted' && command.outcome != 'Rejected') {
      throw new PartnerSyncHandledException(
        'A review outcome of Accepted or Rejected is required.'
      );
    }

    Implementation_Evidence__c evidence = ImplementationEvidenceSelector.selectForUpdate(
      command.evidenceId
    );
    if (
      evidence.Status__c != 'Submitted' &&
      evidence.Status__c != 'Under Review'
    ) {
      throw new PartnerSyncHandledException(
        'This evidence is not in a state that can be reviewed.'
      );
    }

    evidence.Status__c = command.outcome;
    evidence.Review_Outcome__c = command.outcome;
    evidence.Reviewed_By__c = UserInfo.getUserId();
    evidence.Reviewed_On__c = System.now();
    Database.update(evidence, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      command.outcome == 'Accepted'
        ? 'ImplementationEvidenceAccepted'
        : 'ImplementationEvidenceRejected',
      evidence.Implementation__c,
      'Deal_Implementation__c',
      null,
      'Implementation evidence was ' + command.outcome.toLowerCase() + '.',
      'Info'
    );

    if (command.outcome == 'Accepted' && evidence.Milestone__c != null) {
      autoCompleteGatedMilestone(evidence.Milestone__c);
    }
  }

  private static void autoCompleteGatedMilestone(Id milestoneId) {
    List<Implementation_Milestone__c> milestones = [
      SELECT Status__c, Version_Number__c
      FROM Implementation_Milestone__c
      WHERE Id = :milestoneId
      WITH SYSTEM_MODE
    ];
    if (milestones.isEmpty() || milestones[0].Status__c != 'In Progress') {
      return;
    }

    ImplementationMilestoneCommand completeCommand = new ImplementationMilestoneCommand();
    completeCommand.milestoneId = milestoneId;
    completeCommand.expectedVersion = milestones[0].Version_Number__c == null
      ? 0
      : Integer.valueOf(milestones[0].Version_Number__c);
    try {
      ImplementationMilestoneCommandService.complete(completeCommand);
    } catch (Exception ex) {
      // Another guard (e.g. a second required evidence record still
      // outstanding) legitimately keeps the milestone open - defer rather
      // than fail the evidence review itself.
      LoggingService.warn(
        'ImplementationEvidenceCommandService',
        'Milestone auto-completion deferred for ' +
          milestoneId +
          ': ' +
          ex.getMessage()
      );
    }
  }
}
