/**
 * Links Deal_Participant__c records to a deal's current
 * Deal_Protection_Grant__c as shared-protection candidates and, on
 * approval, activates their share. This is the one place Sprint 38
 * touches protection - critically, ActivateDealParticipant never calls
 * into this class, so accepting/activating a participant never itself
 * grants protection (doc §38.27).
 *
 * Deliberate adaptation (see the Sprint 38 plan's Known Adaptation #1 and
 * docs/deal-protection-lifecycle-review.md §3): Sprint 37 built
 * Deal_Protection_Grant__c as a flat "current grant, mutate in place"
 * model with no immutable version chain. Approval here therefore updates
 * the SAME grant's Exclusivity_Type__c/Version_Number__c rather than
 * creating a new versioned grant record - it cannot honestly claim to
 * satisfy the doc's "shared protection creates a new protection version"
 * requirement until Sprint 37's versioning work is completed.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class DealProtectionParticipantCommandService {
  /**
   * Proposes linking an Active participant to the deal's current
   * protection grant. Does not itself grant anything - approval is a
   * separate, governed step.
   *
   * @param command The shared-protection request.
   * @return The new Deal_Protection_Participant__c row, Status__c='Proposed'.
   */
  public static Deal_Protection_Participant__c requestSharedProtection(
    RequestSharedProtectionCommand command
  ) {
    if (
      command == null ||
      command.dealId == null ||
      command.participantId == null ||
      String.isBlank(command.protectionRole)
    ) {
      throw new PartnerSyncHandledException(
        'Deal, participant, and protection role are required.'
      );
    }

    List<Deal_Participant__c> participants = [
      SELECT Id, Status__c, Partner_Account__c
      FROM Deal_Participant__c
      WHERE Id = :command.participantId AND Deal__c = :command.dealId
      WITH SYSTEM_MODE
    ];
    if (participants.isEmpty() || participants[0].Status__c != 'Active') {
      throw new PartnerSyncHandledException(
        'Only an Active participant can be proposed for shared protection.'
      );
    }

    Deal_Protection_Grant__c grant = currentGrant(command.dealId);

    Deal_Protection_Participant__c protectionParticipant = new Deal_Protection_Participant__c(
      Protection__c = grant.Id,
      Deal_Participant__c = command.participantId,
      Partner_Account__c = participants[0].Partner_Account__c,
      Protection_Role__c = command.protectionRole,
      Status__c = 'Proposed',
      Share_Percentage__c = command.sharePercentage,
      Contribution_Percentage__c = command.contributionPercentage
    );
    Database.insert(protectionParticipant, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      'SharedProtectionRequested',
      command.dealId,
      'Deal_Registration__c',
      participants[0].Partner_Account__c,
      'Shared protection was requested for a co-sell participant.',
      'Info'
    );

    return protectionParticipant;
  }

  /**
   * Approves a Proposed shared-protection request: activates the link,
   * determines whether it's the primary or a shared protected partner,
   * and records the composition change on the grant (Adaptation #1).
   *
   * @param command The approval command, including the grant's expected version.
   * @return The activated Deal_Protection_Participant__c.
   */
  public static Deal_Protection_Participant__c approveSharedProtection(
    ApproveSharedProtectionCommand command
  ) {
    if (
      !PermissionService.hasCustomPermission(
        'PartnerSync_Approve_Shared_Protection'
      )
    ) {
      throw new PartnerSyncHandledException(
        'You do not have permission to approve shared protection.'
      );
    }

    if (command == null || command.protectionParticipantId == null) {
      throw new PartnerSyncHandledException(
        'A shared protection request is required.'
      );
    }

    Deal_Protection_Participant__c protectionParticipant = DealProtectionParticipantSelector.selectForUpdate(
      command.protectionParticipantId
    );
    if (protectionParticipant.Status__c != 'Proposed') {
      throw new PartnerSyncHandledException(
        'Only a proposed shared protection request can be approved.'
      );
    }

    List<Deal_Protection_Grant__c> grants = [
      SELECT Id, Deal__c, Version_Number__c, Exclusivity_Type__c
      FROM Deal_Protection_Grant__c
      WHERE Id = :protectionParticipant.Protection__c
      WITH SYSTEM_MODE
      FOR UPDATE
    ];
    if (grants.isEmpty()) {
      throw new PartnerSyncHandledException('Protection grant not found.');
    }
    Deal_Protection_Grant__c grant = grants[0];

    Integer grantVersion = grant.Version_Number__c == null
      ? 0
      : Integer.valueOf(grant.Version_Number__c);
    if (
      command.expectedGrantVersion == null ||
      command.expectedGrantVersion != grantVersion
    ) {
      throw new PartnerSyncHandledException(
        'The protection grant changed. Refresh and retry.'
      );
    }

    // Primary status follows the linked participant's own role (the
    // originating partner is always primary), not insertion order - the
    // originating partner may never get a Deal_Protection_Participant__c
    // row of its own, so "first one approved wins" would incorrectly hand
    // primary status to whichever co-sell partner happens to be approved
    // first.
    List<Deal_Participant__c> linkedParticipants = [
      SELECT Participant_Type__c
      FROM Deal_Participant__c
      WHERE Id = :protectionParticipant.Deal_Participant__c
      WITH SYSTEM_MODE
    ];
    Boolean isPrimary =
      !linkedParticipants.isEmpty() &&
      linkedParticipants[0].Participant_Type__c == 'Originating Partner';

    protectionParticipant.Status__c = 'Active';
    protectionParticipant.Primary__c = isPrimary;
    protectionParticipant.Effective_From__c = System.now();
    Database.update(protectionParticipant, AccessLevel.SYSTEM_MODE);

    if (!isPrimary) {
      grant.Exclusivity_Type__c = 'Shared';
    }
    grant.Version_Number__c = grantVersion + 1;
    Database.update(grant, AccessLevel.SYSTEM_MODE);

    if (!isPrimary) {
      DealParticipantChangePolicyService.evaluate(
        grant.Deal__c,
        'ProtectedParticipantAdded',
        protectionParticipant.Deal_Participant__c
      );
    }

    PlatformEventPublisherService.publish(
      'SharedProtectionGranted',
      grant.Id,
      'Deal_Protection_Grant__c',
      protectionParticipant.Partner_Account__c,
      'Shared protection was granted to a co-sell participant.',
      'Info'
    );

    return protectionParticipant;
  }

  private static Deal_Protection_Grant__c currentGrant(Id dealId) {
    List<Deal_Protection_Grant__c> grants = [
      SELECT Id, Version_Number__c, Exclusivity_Type__c
      FROM Deal_Protection_Grant__c
      WHERE Deal__c = :dealId AND Current__c = TRUE
      WITH SYSTEM_MODE
    ];
    if (grants.isEmpty()) {
      throw new PartnerSyncHandledException(
        'This deal has no current protection grant to share.'
      );
    }
    return grants[0];
  }
}
