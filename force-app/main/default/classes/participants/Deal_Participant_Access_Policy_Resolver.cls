/**
 * Resolves a Deal_Participant__c's access snapshot (Access_Level__c and the
 * 8 capability flags) from Deal_Participant_Access_Policy__mdt, matching
 * on exact Participant_Type__c + Participant_Role__c first, falling back
 * to a Participant_Type__c-only policy. Called from
 * DealParticipantCommandService.activate() - the snapshot this resolves
 * is not directly user-editable afterward.
 */
public without sharing class Deal_Participant_Access_Policy_Resolver {
  /**
   * Applies the best-matching access policy's snapshot to the given
   * participant. If the inviter already requested an explicit access
   * level, that level is kept; the capability flags are always resolved
   * from policy.
   *
   * @param participant The participant to apply the access snapshot to.
   */
  public static void applyAccessSnapshot(Deal_Participant__c participant) {
    Deal_Participant_Access_Policy__mdt policy = resolvePolicy(
      participant.Participant_Type__c,
      participant.Participant_Role__c
    );

    if (policy == null) {
      return;
    }

    if (participant.Access_Level__c == null) {
      participant.Access_Level__c = policy.Access_Level__c;
    }

    participant.Can_View_Commercials__c = policy.Can_View_Commercials__c;
    participant.Can_View_Customer__c = policy.Can_View_Customer__c;
    participant.Can_Edit_Deal__c = policy.Can_Edit_Deal__c;
    participant.Can_Upload_Evidence__c = policy.Can_Upload_Evidence__c;
    participant.Can_View_Protection__c = policy.Can_View_Protection__c;
    participant.Can_Request_Extension__c = policy.Can_Request_Extension__c;
    participant.Can_View_Opportunity__c = policy.Can_View_Opportunity__c;
    participant.Can_Collaborate__c = policy.Can_Collaborate__c;
  }

  private static Deal_Participant_Access_Policy__mdt resolvePolicy(
    String participantType,
    String participantRole
  ) {
    Deal_Participant_Access_Policy__mdt typeOnlyMatch;

    for (Deal_Participant_Access_Policy__mdt candidate : [
      SELECT
        Access_Level__c,
        Can_View_Commercials__c,
        Can_View_Customer__c,
        Can_Edit_Deal__c,
        Can_Upload_Evidence__c,
        Can_View_Protection__c,
        Can_Request_Extension__c,
        Can_View_Opportunity__c,
        Can_Collaborate__c,
        Participant_Type__c,
        Participant_Role__c
      FROM Deal_Participant_Access_Policy__mdt
      WHERE Active__c = TRUE AND Participant_Type__c = :participantType
      WITH SYSTEM_MODE
    ]) {
      if (candidate.Participant_Role__c == participantRole) {
        return candidate;
      }
      if (candidate.Participant_Role__c == null && typeOnlyMatch == null) {
        typeOnlyMatch = candidate;
      }
    }

    return typeOnlyMatch;
  }
}
