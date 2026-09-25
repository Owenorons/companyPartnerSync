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
}
