/**
 * Executes Deal_Participant__c lifecycle commands: invite, accept, decline,
 * activate, suspend, resume, remove, change role, change access. Follows
 * the same FOR UPDATE + Version_Number__c pattern as every other command
 * service in this codebase (see LeadAssignmentCommandService), plus an
 * Active_Participant_Key__c uniqueness constraint preventing two active
 * participants from occupying the same deal/type/actor/role slot.
 *
 * Sharing materialization (DealParticipantSharingService) and access-policy
 * resolution (Deal_Participant_Access_Policy_Resolver) are wired into
 * activate()/suspend()/resume()/remove()/changeAccess() by later phases of
 * the Sprint 38 build, not this one - see the Sprint 38 plan.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class DealParticipantCommandService {
  private static final Set<String> DEAL_ELIGIBLE_STATUSES = new Set<String>{
    'Approved',
    'Approved with Conditions'
  };

  // Types with an actual partner-account relationship to gate - internal
  // team types (Internal Sales, Channel Manager, Account Executive,
  // Solution Engineer, Executive Sponsor, Customer Contact) have no partner
  // relationship to check.
  private static final Set<String> PARTNER_PARTICIPANT_TYPES = new Set<String>{
    'Co-Sell Partner',
    'Referral Partner',
    'Distributor',
    'Reseller',
    'Implementation Partner',
    'Technology Partner'
  };

  /**
   * Executes the given participant command, dispatching to the matching
   * action.
   *
   * @param command The participant command to execute.
   * @return The resulting Deal_Participant__c record.
   */
  public static Deal_Participant__c execute(DealParticipantCommand command) {
    command.validate();

    if (command.action == 'Invite') {
      DealParticipantOutcome outcome = invite(command);
      if (outcome.outcome != DealParticipantOutcome.INVITED) {
        throw new PartnerSyncHandledException(outcome.message);
      }
      return outcome.participant;
    }

    Deal_Participant__c participant = DealParticipantSelector.selectForUpdate(
      command.participantId
    );

    if (command.action == 'Accept' || command.action == 'Decline') {
      assertAuthority(participant);
    }

    Integer version = participant.Version_Number__c == null
      ? 0
      : Integer.valueOf(participant.Version_Number__c);
    if (command.expectedVersion == null || command.expectedVersion != version) {
      throw new PartnerSyncHandledException(
        'The deal participant changed. Refresh before retrying.'
      );
    }

    if (command.action == 'Accept') {
      accept(participant);
    } else if (command.action == 'Decline') {
      decline(participant, command);
    } else if (command.action == 'Activate') {
      activate(participant);
    } else if (command.action == 'Suspend') {
      suspend(participant, command);
    } else if (command.action == 'Resume') {
      resume(participant);
    } else if (command.action == 'Remove') {
      remove(participant, command);
    } else if (command.action == 'ChangeRole') {
      changeRole(participant, command);
    } else if (command.action == 'ChangeAccess') {
      changeAccess(participant, command);
    } else if (command.action == 'Expire') {
      expire(participant);
    } else {
      throw new PartnerSyncHandledException(
        'Unsupported participant action: ' + command.action
      );
    }

    participant.Version_Number__c = version + 1;
    Database.update(participant, AccessLevel.SYSTEM_MODE);

    if (RECONCILES_SHARING.contains(command.action)) {
      // Runs after the update above has committed, so
      // DealParticipantSharingService's own fresh queries see the
      // just-applied status/access level - same "after commit, same
      // transaction" shape as DealCommandService.activateProtection().
      DealParticipantSharingService.reconcileForParticipant(participant.Id);
    }

    return participant;
  }

  private static final Set<String> RECONCILES_SHARING = new Set<String>{
    'Activate',
    'Suspend',
    'Resume',
    'Remove',
    'ChangeAccess'
  };

  // ---------------------------------------------------------------------
  // Invite
  // ---------------------------------------------------------------------

  private static DealParticipantOutcome invite(DealParticipantCommand command) {
    Deal_Registration__c deal = selectDeal(command.dealId);
    if (!DEAL_ELIGIBLE_STATUSES.contains(deal.Status__c)) {
      return new DealParticipantOutcome(
        DealParticipantOutcome.PARTNER_INELIGIBLE,
        null,
        'The deal is not in a status that allows co-sell participation.'
      );
    }

    assertInviterAuthorized(deal);

    if (PARTNER_PARTICIPANT_TYPES.contains(command.participantType)) {
      Account targetPartner = selectPartnerAccount(command.partnerAccountId);
      if (targetPartner.Partner_Status__c != 'Active') {
        return new DealParticipantOutcome(
          DealParticipantOutcome.PARTNER_INELIGIBLE,
          null,
          'The target partner account is not active.'
        );
      }

      if (
        !PartnerAccountRelationshipService.allowsCoSell(
          deal.Partner_Account__c,
          command.partnerAccountId
        )
      ) {
        return new DealParticipantOutcome(
          DealParticipantOutcome.RELATIONSHIP_REQUIRED,
          null,
          'No active partner relationship permits this collaboration.'
        );
      }
    }

    // Territory/product eligibility (doc §38.12 step 7) and conflict
    // restrictions (step 9, real in a later phase) are deliberate no-ops
    // here - see the Sprint 38 plan's Known Adaptations.

    Id actorId = DealParticipantDomain.resolveActorId(command);
    String activeKey = DealParticipantDomain.buildActiveKey(
      command.dealId,
      command.participantType,
      actorId,
      command.participantRole
    );

    if (DealParticipantSelector.selectActiveForSlot(activeKey) != null) {
      return new DealParticipantOutcome(
        DealParticipantOutcome.ALREADY_PARTICIPATING,
        null,
        'This partner already has an active or pending participation for this role.'
      );
    }

    Boolean autoAccept = command.autoAccept == true;
    Datetime now = System.now();
    Datetime respondBy = command.respondBy != null
      ? command.respondBy
      : DealParticipantSlaService.computeRespondBy(
          command.participantType,
          now
        );

    Deal_Participant__c participant = new Deal_Participant__c(
      Deal__c = command.dealId,
      Partner_Account__c = command.partnerAccountId,
      Contact__c = command.targetContactId,
      User__c = command.targetUserId,
      Participant_Type__c = command.participantType,
      Participant_Role__c = command.participantRole,
      Status__c = autoAccept ? 'Accepted' : 'Invited',
      Invited_By__c = UserInfo.getUserId(),
      Invited_On__c = now,
      Accepted_On__c = autoAccept ? now : null,
      Respond_By__c = autoAccept ? null : respondBy,
      Invitation_Reason__c = command.reason,
      Active_Participant_Key__c = activeKey,
      Last_Activity_On__c = now,
      Version_Number__c = 0
    );

    // Duplicate-key insert failures (a concurrent invite winning the race)
    // surface as a DmlException from this insert - the friendly pre-check
    // above is the common-case UX, this is the hard backstop.
    Database.insert(participant, AccessLevel.SYSTEM_MODE);

    DealParticipantChangePolicyService.evaluate(
      command.dealId,
      'ParticipantAdded',
      participant.Id
    );

    PlatformEventPublisherService.publish(
      'DealParticipantInvited',
      command.dealId,
      'Deal_Registration__c',
      command.partnerAccountId,
      'A co-sell participant was invited.',
      'Info'
    );

    LoggingService.info(
      'DealParticipantCommandService',
      'Deal participant invited. ParticipantId=' + participant.Id
    );

    return new DealParticipantOutcome(
      DealParticipantOutcome.INVITED,
      participant,
      'Invited.'
    );
  }

  private static void assertInviterAuthorized(Deal_Registration__c deal) {
    if (PartnerAccessService.isInternalUser()) {
      return;
    }
    Id currentPartnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();
    if (deal.Partner_Account__c == currentPartnerAccountId) {
      return;
    }
    if (
      DealParticipantSelector.hasActiveParticipant(
        deal.Id,
        currentPartnerAccountId
      )
    ) {
      return;
    }
    throw new PartnerSyncHandledException(
      'Current user lacks authority to invite a participant to this deal.'
    );
  }

  // ---------------------------------------------------------------------
  // Accept / Decline
  // ---------------------------------------------------------------------

  private static void accept(Deal_Participant__c participant) {
    requireStatus(participant, 'Invited');
    participant.Status__c = 'Accepted';
    participant.Accepted_On__c = System.now();
    participant.Last_Activity_On__c = System.now();

    PlatformEventPublisherService.publish(
      'DealParticipantAccepted',
      participant.Deal__c,
      'Deal_Registration__c',
      participant.Partner_Account__c,
      'A co-sell participant accepted their invitation.',
      'Info'
    );
  }

  private static void decline(
    Deal_Participant__c participant,
    DealParticipantCommand command
  ) {
    requireStatus(participant, 'Invited');
    participant.Status__c = 'Declined';
    participant.Declined_On__c = System.now();
    participant.Decline_Reason__c = command.reason;
    participant.Active_Participant_Key__c = null;

    PlatformEventPublisherService.publish(
      'DealParticipantDeclined',
      participant.Deal__c,
      'Deal_Registration__c',
      participant.Partner_Account__c,
      'A co-sell participant declined their invitation.',
      'Info'
    );
  }

  private static void assertAuthority(Deal_Participant__c participant) {
    if (PartnerAccessService.isInternalUser()) {
      return;
    }
    if (
      participant.Partner_Account__c !=
      PartnerAccessService.getCurrentPartnerAccountId()
    ) {
      throw new PartnerSyncHandledException(
        'Current user lacks authority for this participation.'
      );
    }
  }

  // ---------------------------------------------------------------------
  // Activate / Suspend / Resume
  // ---------------------------------------------------------------------

  private static void activate(Deal_Participant__c participant) {
    requireStatus(participant, 'Accepted');
    participant.Status__c = 'Active';
    participant.Effective_From__c = System.now();
    participant.Last_Activity_On__c = System.now();

    Deal_Participant_Access_Policy_Resolver.applyAccessSnapshot(participant);

    PlatformEventPublisherService.publish(
      'DealParticipantActivated',
      participant.Deal__c,
      'Deal_Registration__c',
      participant.Partner_Account__c,
      'A co-sell participant was activated.',
      'Info'
    );
  }

  private static void suspend(
    Deal_Participant__c participant,
    DealParticipantCommand command
  ) {
    requireStatus(participant, 'Active');
    participant.Status__c = 'Suspended';
    participant.Last_Activity_On__c = System.now();

    PlatformEventPublisherService.publish(
      'DealParticipantSuspended',
      participant.Deal__c,
      'Deal_Registration__c',
      participant.Partner_Account__c,
      'A co-sell participant was suspended.',
      'Info'
    );
  }

  private static void resume(Deal_Participant__c participant) {
    requireStatus(participant, 'Suspended');
    participant.Status__c = 'Active';
    participant.Last_Activity_On__c = System.now();

    PlatformEventPublisherService.publish(
      'DealParticipantResumed',
      participant.Deal__c,
      'Deal_Registration__c',
      participant.Partner_Account__c,
      'A suspended co-sell participant was resumed.',
      'Info'
    );
  }

  // ---------------------------------------------------------------------
  // Remove
  // ---------------------------------------------------------------------

  private static void remove(
    Deal_Participant__c participant,
    DealParticipantCommand command
  ) {
    if (
      participant.Status__c == 'Removed' ||
      participant.Status__c == 'Declined' ||
      participant.Status__c == 'Superseded' ||
      participant.Status__c == 'Expired'
    ) {
      throw new PartnerSyncHandledException(
        'This participant has already exited the deal.'
      );
    }

    assertRemovable(participant);

    participant.Status__c = 'Removed';
    participant.Removed_On__c = System.now();
    participant.Removal_Reason__c = command.reason;
    participant.Active_Participant_Key__c = null;

    DealParticipantChangePolicyService.evaluate(
      participant.Deal__c,
      'ParticipantRemoved',
      participant.Id
    );

    PlatformEventPublisherService.publish(
      'DealParticipantRemoved',
      participant.Deal__c,
      'Deal_Registration__c',
      participant.Partner_Account__c,
      'A co-sell participant was removed.',
      'Info'
    );
  }

  // Dependency-evaluation guard (doc §38.29). Ships the checks that have
  // real data to test against today: active shared-protection linkage, and
  // an open blocking review/approval assigned to this participant's own
  // User__c. OpportunityReassignmentRequired and revenue-attribution
  // checks are deferred - no Opportunity/attribution model exists on
  // Deal_Participant__c yet (Sprint 39's job) - see the Sprint 38 plan's
  // Known Adaptations.
  private static void assertRemovable(Deal_Participant__c participant) {
    if (
      DealProtectionParticipantSelector.selectActiveForParticipant(
        participant.Id
      )
    ) {
      throw new PartnerSyncHandledException(
        'This participant has an active shared protection interest and must be unlinked from protection before removal.'
      );
    }

    if (participant.User__c == null) {
      return;
    }

    if (
      [
        SELECT COUNT()
        FROM Deal_Review__c
        WHERE
          Deal__c = :participant.Deal__c
          AND Assigned_To__c = :participant.User__c
          AND Status__c NOT IN ('Completed', 'Waived')
        WITH SYSTEM_MODE
      ] > 0
    ) {
      throw new PartnerSyncHandledException(
        'This participant has an open review assignment and cannot be removed yet.'
      );
    }

    if (
      [
        SELECT COUNT()
        FROM Approval__c
        WHERE
          Target_Record_Id__c = :participant.Deal__c
          AND Object_Name__c = 'Deal_Registration__c'
          AND Assigned_To__c = :participant.User__c
          AND Status__c = 'Pending'
        WITH SYSTEM_MODE
      ] > 0
    ) {
      throw new PartnerSyncHandledException(
        'This participant has an open approval assignment and cannot be removed yet.'
      );
    }
  }

  // ---------------------------------------------------------------------
  // Change role / access
  // ---------------------------------------------------------------------

  private static void changeRole(
    Deal_Participant__c participant,
    DealParticipantCommand command
  ) {
    if (String.isBlank(command.participantRole)) {
      throw new PartnerSyncHandledException(
        'A new participant role is required.'
      );
    }
    participant.Participant_Role__c = command.participantRole;
    participant.Last_Activity_On__c = System.now();

    DealParticipantChangePolicyService.evaluate(
      participant.Deal__c,
      'RoleChanged',
      participant.Id
    );

    PlatformEventPublisherService.publish(
      'DealParticipantRoleChanged',
      participant.Deal__c,
      'Deal_Registration__c',
      participant.Partner_Account__c,
      'A co-sell participant\'s role was changed.',
      'Info'
    );
  }

  private static void changeAccess(
    Deal_Participant__c participant,
    DealParticipantCommand command
  ) {
    if (String.isBlank(command.requestedAccessLevel)) {
      throw new PartnerSyncHandledException('A new access level is required.');
    }
    participant.Access_Level__c = command.requestedAccessLevel;
    participant.Last_Activity_On__c = System.now();
  }

  // ---------------------------------------------------------------------
  // Expire (issued by DealParticipantExpiryBatch in a later phase)
  // ---------------------------------------------------------------------

  private static void expire(Deal_Participant__c participant) {
    requireStatus(participant, 'Invited', 'Accepted');
    participant.Status__c = 'Expired';
    participant.Active_Participant_Key__c = null;
  }

  private static void requireStatus(
    Deal_Participant__c participant,
    String expected
  ) {
    if (participant.Status__c != expected) {
      throw new PartnerSyncHandledException(
        'This action requires the participant to be ' + expected + '.'
      );
    }
  }

  private static void requireStatus(
    Deal_Participant__c participant,
    String expectedA,
    String expectedB
  ) {
    if (
      participant.Status__c != expectedA &&
      participant.Status__c != expectedB
    ) {
      throw new PartnerSyncHandledException(
        'This action requires the participant to be ' +
          expectedA +
          ' or ' +
          expectedB +
          '.'
      );
    }
  }

  private static Deal_Registration__c selectDeal(Id dealId) {
    List<Deal_Registration__c> rows = [
      SELECT Id, Status__c, Partner_Account__c
      FROM Deal_Registration__c
      WHERE Id = :dealId
      WITH SYSTEM_MODE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Deal registration not found.');
    }

    return rows[0];
  }

  private static Account selectPartnerAccount(Id partnerAccountId) {
    List<Account> rows = [
      SELECT Id, Partner_Status__c
      FROM Account
      WHERE Id = :partnerAccountId
      WITH SYSTEM_MODE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Partner account not found.');
    }

    return rows[0];
  }
}
