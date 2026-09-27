/**
 * Assigns/removes Implementation_Participant__c rows - the junction that
 * makes an existing Deal_Participant__c operational on a
 * Deal_Implementation__c (see docs/architecture-design-and-enhancement.md
 * Sprint 40 §40.13/§40.37: "Sprint 38 participants now become
 * operational"). Not a new team/person model - every row here points at
 * a participant that already went through DealParticipantCommandService.
 *
 * Activation/deactivation reconciles Deal_Implementation__c sharing via
 * ImplementationParticipantSharingService, the same "recompute the whole
 * desired state, grant/revoke the delta" shape DealParticipantSharingService
 * uses for deals.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ImplementationParticipantCommandService {
  private static final Set<String> ASSIGN_PERMISSIONS = new Set<String>{
    'PartnerSync_Assign_Partner_Implementation_Role',
    'PartnerSync_Manage_Implementation'
  };

  /**
   * Links an existing Deal_Participant__c to an implementation, then
   * reconciles sharing so the participant's partner account gains access
   * to the implementation.
   *
   * @param command Assignment details (implementationId, dealParticipantId, role, primary, responsibilitySummary).
   * @return The inserted Implementation_Participant__c.
   */
  public static Implementation_Participant__c assign(
    ImplementationParticipantCommand command
  ) {
    if (command.implementationId == null || command.dealParticipantId == null) {
      throw new PartnerSyncHandledException(
        'Implementation and deal participant are required.'
      );
    }
    if (String.isBlank(command.role)) {
      throw new PartnerSyncHandledException(
        'A delivery role is required to assign a participant.'
      );
    }

    Deal_Implementation__c implementation = ImplementationSelector.selectForUpdate(
      command.implementationId
    );
    Deal_Participant__c dealParticipant = selectDealParticipant(
      command.dealParticipantId
    );

    if (dealParticipant.Deal__c != implementation.Deal__c) {
      throw new PartnerSyncHandledException(
        'The deal participant does not belong to this implementation\'s deal.'
      );
    }
    if (dealParticipant.Status__c != 'Active') {
      throw new PartnerSyncHandledException(
        'Only an active deal participant can be assigned a delivery role.'
      );
    }

    assertAssignAuthority(dealParticipant.Partner_Account__c);

    Implementation_Participant__c participant = new Implementation_Participant__c(
      Implementation__c = command.implementationId,
      Deal_Participant__c = command.dealParticipantId,
      Role__c = command.role,
      Status__c = 'Active',
      Effective_From__c = System.now(),
      Primary__c = command.primary == true,
      Responsibility_Summary__c = command.responsibilitySummary
    );
    Database.insert(participant, AccessLevel.SYSTEM_MODE);

    ImplementationParticipantSharingService.reconcileForImplementation(
      command.implementationId
    );

    PlatformEventPublisherService.publish(
      'ImplementationParticipantAssigned',
      command.implementationId,
      'Deal_Implementation__c',
      dealParticipant.Partner_Account__c,
      'A delivery participant was assigned to the implementation.',
      'Info'
    );

    return participant;
  }

  /**
   * Deactivates an implementation participant and reconciles sharing so
   * access is revoked if no other active participant from the same
   * partner account still justifies it.
   *
   * @param command Removal details (implementationParticipantId, expectedVersion via ImplementationCommand-style version guard is not used here - see class comment).
   * @return The updated Implementation_Participant__c.
   */
  public static Implementation_Participant__c remove(
    ImplementationParticipantCommand command
  ) {
    if (command.implementationParticipantId == null) {
      throw new PartnerSyncHandledException(
        'An implementation participant Id is required to remove it.'
      );
    }

    Implementation_Participant__c participant = ImplementationParticipantSelector.selectForUpdate(
      command.implementationParticipantId
    );

    if (participant.Status__c != 'Active') {
      return participant;
    }

    assertAssignAuthority(participant.Deal_Participant__r.Partner_Account__c);

    participant.Status__c = 'Inactive';
    participant.Effective_To__c = System.now();
    participant.Version_Number__c = participant.Version_Number__c == null
      ? 1
      : Integer.valueOf(participant.Version_Number__c) + 1;
    Database.update(participant, AccessLevel.SYSTEM_MODE);

    ImplementationParticipantSharingService.reconcileForImplementation(
      participant.Implementation__c
    );

    PlatformEventPublisherService.publish(
      'ImplementationParticipantRemoved',
      participant.Implementation__c,
      'Deal_Implementation__c',
      participant.Deal_Participant__r.Partner_Account__c,
      'A delivery participant was removed from the implementation.',
      'Info'
    );

    return participant;
  }

  private static void assertAssignAuthority(Id partnerAccountId) {
    Boolean hasAssignPermission = false;
    for (String permission : ASSIGN_PERMISSIONS) {
      if (DealLifecyclePermissionService.hasPermission(permission)) {
        hasAssignPermission = true;
        break;
      }
    }
    if (!hasAssignPermission) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority to assign implementation delivery roles.'
      );
    }
    if (PartnerAccessService.isInternalUser()) {
      return;
    }
    if (partnerAccountId != PartnerAccessService.getCurrentPartnerAccountId()) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority for this participant\'s partner account.'
      );
    }
  }

  private static Deal_Participant__c selectDealParticipant(
    Id dealParticipantId
  ) {
    List<Deal_Participant__c> rows = [
      SELECT Id, Deal__c, Partner_Account__c, Status__c
      FROM Deal_Participant__c
      WHERE Id = :dealParticipantId
      WITH SYSTEM_MODE
    ];
    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Deal participant not found.');
    }
    return rows[0];
  }
}
