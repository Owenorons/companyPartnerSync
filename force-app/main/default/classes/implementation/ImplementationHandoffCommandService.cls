/**
 * Executes Deal_Implementation_Handoff__c commands: submit, accept,
 * return. submit() validates required fields and returns a committed
 * outcome rather than throwing for every rejection, mirroring
 * DealParticipantOutcome/DealOpportunityOutcome's established framing
 * (doc §40.11).
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ImplementationHandoffCommandService {
  // Deal_Implementation_Policy__mdt is an org singleton, so tests can't
  // seed alternate CMDT rows per case - same test-override shape as
  // DealLifecyclePermissionService.testOverrides.
  @TestVisible
  private static Boolean testRequireEvidenceOverride;

  /**
   * Submits a new handoff (or resubmits after a return) for an
   * implementation, validating required fields first.
   *
   * @param command Implementation id + submitted handoff fields.
   * @return The outcome of the submission attempt.
   */
  public static ImplementationHandoffOutcome submit(
    ImplementationHandoffCommand command
  ) {
    PartnerAccessService.assertInternalUser();
    if (command.implementationId == null) {
      throw new PartnerSyncHandledException(
        'An implementation is required to submit a handoff.'
      );
    }

    if (
      String.isBlank(command.customerObjectives) ||
      String.isBlank(command.solutionSummary)
    ) {
      return new ImplementationHandoffOutcome(
        ImplementationHandoffOutcome.INFORMATION_REQUIRED,
        null,
        'Customer objectives and solution summary are required.'
      );
    }
    if (command.deliveryOwnerId == null) {
      return new ImplementationHandoffOutcome(
        ImplementationHandoffOutcome.DELIVERY_OWNER_REQUIRED,
        null,
        'A delivery owner must be assigned before this handoff can be submitted.'
      );
    }
    if (String.isBlank(command.scopeSummary)) {
      return new ImplementationHandoffOutcome(
        ImplementationHandoffOutcome.SCOPE_INCOMPLETE,
        null,
        'A scope summary is required before this handoff can be submitted.'
      );
    }
    Deal_Implementation_Policy__mdt policy = resolvePolicy();
    Boolean requireEvidence = Test.isRunningTest() &&
      testRequireEvidenceOverride != null
      ? testRequireEvidenceOverride
      : policy.Require_Evidence__c == true;
    Boolean evidenceComplete = command.requiredEvidenceComplete == true;
    if (requireEvidence && !evidenceComplete) {
      return new ImplementationHandoffOutcome(
        ImplementationHandoffOutcome.EVIDENCE_REQUIRED,
        null,
        'Required evidence must be attached before this handoff can be submitted.'
      );
    }

    Deal_Implementation_Handoff__c handoff = new Deal_Implementation_Handoff__c(
      Implementation__c = command.implementationId,
      Status__c = 'Submitted',
      Requested_By__c = UserInfo.getUserId(),
      Sales_Owner__c = command.salesOwnerId,
      Delivery_Owner__c = command.deliveryOwnerId,
      Customer_Objectives__c = command.customerObjectives,
      Solution_Summary__c = command.solutionSummary,
      Commercial_Summary__c = command.commercialSummary,
      Scope_Summary__c = command.scopeSummary,
      Key_Assumptions__c = command.keyAssumptions,
      Known_Risks__c = command.knownRisks,
      Dependencies__c = command.dependencies,
      Target_Start_Date__c = command.targetStartDate,
      Target_Completion_Date__c = command.targetCompletionDate,
      Required_Evidence_Complete__c = evidenceComplete,
      Version_Number__c = 0
    );
    Database.insert(handoff, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'ImplementationHandoffSubmitted',
      command.implementationId,
      'Deal_Implementation__c',
      null,
      'An implementation handoff was submitted.',
      'Info'
    );

    return new ImplementationHandoffOutcome(
      ImplementationHandoffOutcome.ACCEPTED,
      handoff,
      'Submitted.'
    );
  }

  /**
   * Accepts a submitted handoff, transitioning the linked implementation
   * from Planned/Handoff Pending to Handoff Accepted -> Not Started.
   *
   * @param command Handoff id + expected version.
   */
  public static void accept(ImplementationHandoffCommand command) {
    PartnerAccessService.assertInternalUser();
    assertPermission('PartnerSync_Accept_Implementation_Handoff');

    Deal_Implementation_Handoff__c handoff = selectAndCheckVersion(command);
    if (handoff.Status__c != 'Submitted') {
      throw new PartnerSyncHandledException(
        'This handoff is not in a state that can be accepted.'
      );
    }

    handoff.Status__c = 'Accepted';
    handoff.Version_Number__c = versionAfter(handoff);
    Database.update(handoff, AccessLevel.SYSTEM_MODE);

    Deal_Implementation__c implementation = ImplementationSelector.selectForUpdate(
      handoff.Implementation__c
    );
    implementation.Status__c = 'Not Started';
    implementation.Version_Number__c =
      (implementation.Version_Number__c == null
        ? 0
        : Integer.valueOf(implementation.Version_Number__c)) + 1;
    Database.update(implementation, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'ImplementationHandoffAccepted',
      handoff.Implementation__c,
      'Deal_Implementation__c',
      null,
      'An implementation handoff was accepted.',
      'Info'
    );
  }

  /**
   * Returns a submitted handoff to Draft, requiring a reason.
   *
   * @param command Handoff id + expected version + reason.
   */
  public static void doReturn(ImplementationHandoffCommand command) {
    PartnerAccessService.assertInternalUser();
    assertPermission('PartnerSync_Accept_Implementation_Handoff');
    if (String.isBlank(command.reason)) {
      throw new PartnerSyncHandledException(
        'A reason is required to return a handoff.'
      );
    }

    Deal_Implementation_Handoff__c handoff = selectAndCheckVersion(command);
    if (handoff.Status__c != 'Submitted') {
      throw new PartnerSyncHandledException(
        'This handoff is not in a state that can be returned.'
      );
    }

    handoff.Status__c = 'Returned';
    handoff.Returned_Reason__c = command.reason;
    handoff.Version_Number__c = versionAfter(handoff);
    Database.update(handoff, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'ImplementationHandoffReturned',
      handoff.Implementation__c,
      'Deal_Implementation__c',
      null,
      'An implementation handoff was returned for revision.',
      'Info'
    );
  }

  private static void assertPermission(String permissionName) {
    if (!DealLifecyclePermissionService.hasPermission(permissionName)) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to perform this handoff action.'
      );
    }
  }

  private static Deal_Implementation_Handoff__c selectAndCheckVersion(
    ImplementationHandoffCommand command
  ) {
    if (command.handoffId == null) {
      throw new PartnerSyncHandledException(
        'A handoff is required for this command.'
      );
    }
    Deal_Implementation_Handoff__c handoff = ImplementationHandoffSelector.selectForUpdate(
      command.handoffId
    );
    Integer version = handoff.Version_Number__c == null
      ? 0
      : Integer.valueOf(handoff.Version_Number__c);
    if (command.expectedVersion == null || command.expectedVersion != version) {
      throw new PartnerSyncHandledException(
        'This handoff changed. Refresh before retrying.'
      );
    }
    return handoff;
  }

  private static Integer versionAfter(Deal_Implementation_Handoff__c handoff) {
    Integer current = handoff.Version_Number__c == null
      ? 0
      : Integer.valueOf(handoff.Version_Number__c);
    return current + 1;
  }

  private static Deal_Implementation_Policy__mdt resolvePolicy() {
    List<Deal_Implementation_Policy__mdt> rows = [
      SELECT Require_Evidence__c
      FROM Deal_Implementation_Policy__mdt
      WHERE Active__c = TRUE
      WITH SYSTEM_MODE
      ORDER BY Priority__c DESC NULLS LAST
      LIMIT 1
    ];
    return rows.isEmpty() ? new Deal_Implementation_Policy__mdt() : rows[0];
  }
}
