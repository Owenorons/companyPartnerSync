/**
 * Selector layer for the Deal_Participant__c aggregate.
 */
public without sharing class DealParticipantSelector {
  /**
   * Locks and reads a single participant record by Id, for a command to
   * apply a decision to.
   *
   * @param participantId Id of the participant to load.
   * @return The locked Deal_Participant__c record.
   */
  public static Deal_Participant__c selectForUpdate(Id participantId) {
    List<Deal_Participant__c> rows = [
      SELECT
        Id,
        Deal__c,
        Account__c,
        Contact__c,
        User__c,
        Partner_Account__c,
        Invited_By__c,
        Approved_By__c,
        Participant_Type__c,
        Participant_Role__c,
        Status__c,
        Access_Level__c,
        Can_View_Commercials__c,
        Can_View_Customer__c,
        Can_Edit_Deal__c,
        Can_Upload_Evidence__c,
        Can_View_Protection__c,
        Can_Request_Extension__c,
        Can_View_Opportunity__c,
        Can_Collaborate__c,
        Invited_On__c,
        Respond_By__c,
        Accepted_On__c,
        Declined_On__c,
        Effective_From__c,
        Effective_To__c,
        Removed_On__c,
        Last_Activity_On__c,
        Active_Participant_Key__c,
        Version_Number__c,
        Invitation_Reason__c,
        Decline_Reason__c,
        Removal_Reason__c
      FROM Deal_Participant__c
      WHERE Id = :participantId
      WITH SYSTEM_MODE
      FOR UPDATE
    ];

    if (rows.isEmpty()) {
      throw new PartnerSyncHandledException('Deal participant not found.');
    }

    return rows[0];
  }

  /**
   * Queries the active participant occupying a given deal/type/actor/role
   * slot, if any, keyed off Active_Participant_Key__c.
   *
   * @param activeKey The composed active-participant key to look up.
   * @return The active participant, or null if the slot is unoccupied.
   */
  public static Deal_Participant__c selectActiveForSlot(String activeKey) {
    List<Deal_Participant__c> rows = [
      SELECT Id, Status__c, Version_Number__c
      FROM Deal_Participant__c
      WHERE Active_Participant_Key__c = :activeKey
      WITH SYSTEM_MODE
      LIMIT 1
    ];

    return rows.isEmpty() ? null : rows[0];
  }

  /**
   * Queries every active (Accepted or Active status) participant for a deal.
   *
   * @param dealId Id of the deal.
   * @return The deal's active participants.
   */
  public static List<Deal_Participant__c> selectActiveParticipantsForDeal(
    Id dealId
  ) {
    return [
      SELECT
        Id,
        Deal__c,
        Partner_Account__c,
        Participant_Type__c,
        Participant_Role__c,
        Status__c,
        Access_Level__c
      FROM Deal_Participant__c
      WHERE Deal__c = :dealId AND Status__c IN ('Accepted', 'Active')
      WITH SYSTEM_MODE
    ];
  }

  /**
   * Queries every non-terminal participant for a deal (Invited through
   * Suspended), for display in the deal-team UI - a broader set than
   * selectActiveParticipantsForDeal, which excludes still-pending
   * invitations.
   *
   * @param dealId Id of the deal.
   * @return The deal's currently-visible participants.
   */
  public static List<Deal_Participant__c> selectVisibleParticipantsForDeal(
    Id dealId
  ) {
    return [
      SELECT
        Id,
        Deal__c,
        Partner_Account__c,
        Partner_Account__r.Name,
        Participant_Type__c,
        Participant_Role__c,
        Status__c,
        Access_Level__c,
        Invited_On__c,
        Respond_By__c,
        Effective_From__c,
        Version_Number__c
      FROM Deal_Participant__c
      WHERE
        Deal__c = :dealId
        AND Status__c IN ('Invited', 'Accepted', 'Active', 'Suspended')
      WITH SYSTEM_MODE
      ORDER BY CreatedDate ASC
    ];
  }

  /**
   * Queries Invited participants across deals, for the internal co-sell
   * workbench's pending-invitations queue.
   *
   * @return Up to 200 Invited participants, oldest first.
   */
  public static List<Deal_Participant__c> selectPendingInvitations() {
    return [
      SELECT
        Id,
        Deal__c,
        Partner_Account__c,
        Partner_Account__r.Name,
        Participant_Type__c,
        Participant_Role__c,
        Status__c,
        Access_Level__c,
        Invited_On__c,
        Respond_By__c,
        Effective_From__c,
        Version_Number__c
      FROM Deal_Participant__c
      WHERE Status__c = 'Invited'
      WITH SYSTEM_MODE
      ORDER BY Invited_On__c ASC
      LIMIT 200
    ];
  }

  /**
   * Bulk-loads active participants for a set of deals, for reconciliation
   * and dashboard-style callers that need every deal's roster at once.
   *
   * @param dealIds Ids of the deals to load participants for.
   * @return Active participants across all the given deals.
   */
  public static List<Deal_Participant__c> selectByDealIds(Set<Id> dealIds) {
    return [
      SELECT
        Id,
        Deal__c,
        Partner_Account__c,
        Participant_Type__c,
        Participant_Role__c,
        Status__c,
        Access_Level__c
      FROM Deal_Participant__c
      WHERE Deal__c IN :dealIds AND Status__c IN ('Accepted', 'Active')
      WITH SYSTEM_MODE
    ];
  }

  /**
   * Indicates whether an Active participant exists for a deal under a
   * given partner account - the co-sell-partner analogue of the deal's
   * own Partner_Account__c check, used to extend partner-facing deal
   * visibility to co-sell participants.
   *
   * @param dealId Id of the deal.
   * @param partnerAccountId Id of the partner account to check.
   * @return True if an Active participant exists for that deal/partner pair.
   */
  public static Boolean hasActiveParticipant(Id dealId, Id partnerAccountId) {
    return [
        SELECT COUNT()
        FROM Deal_Participant__c
        WHERE
          Deal__c = :dealId
          AND Partner_Account__c = :partnerAccountId
          AND Status__c = 'Active'
        WITH SYSTEM_MODE
      ] > 0;
  }

  /**
   * Queries participants with an SLA concern, for the internal Co-Sell
   * Workbench's "Participant SLA Breaches" view: invitations already
   * flagged at risk (still open) and ones that expired outright.
   *
   * @return Up to 200 at-risk or expired participants, most recently flagged/expired first.
   */
  public static List<Deal_Participant__c> selectSlaBreaches() {
    return [
      SELECT
        Id,
        Deal__c,
        Partner_Account__c,
        Partner_Account__r.Name,
        Participant_Type__c,
        Participant_Role__c,
        Status__c,
        Access_Level__c,
        Invited_On__c,
        Respond_By__c,
        Effective_From__c,
        Version_Number__c
      FROM Deal_Participant__c
      WHERE
        (Status__c IN ('Invited', 'Accepted')
        AND At_Risk_Notified__c = TRUE)
        OR Status__c = 'Expired'
      WITH SYSTEM_MODE
      ORDER BY LastModifiedDate DESC
      LIMIT 200
    ];
  }

  /**
   * Queries recent participant-related audit entries, for the internal
   * Co-Sell Workbench's "Participant Changes" view. Sourced from
   * Audit_Log__c, written by AuditEventConsumerService for the participant
   * lifecycle event types it maps.
   *
   * @return Up to 100 participant-related Audit_Log__c rows, most recent first.
   */
  public static List<Audit_Log__c> selectRecentParticipantChanges() {
    return [
      SELECT Record_Id__c, Action__c, Performed_By_Name__c, Audit_Timestamp__c
      FROM Audit_Log__c
      WHERE
        Object_Name__c = 'Deal_Registration__c'
        AND Action__c IN (
          'Invite Participant',
          'Accept Participation',
          'Decline Participation',
          'Activate Participant',
          'Suspend Participant',
          'Resume Participant',
          'Remove Participant',
          'Change Participant Role',
          'Request Shared Protection',
          'Grant Shared Protection',
          'Transfer Deal Ownership'
        )
      WITH SYSTEM_MODE
      ORDER BY Audit_Timestamp__c DESC
      LIMIT 100
    ];
  }
}
