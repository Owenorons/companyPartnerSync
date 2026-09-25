/**
 * Resolves a co-sell invitation's response deadline from
 * Deal_Participant_SLA__mdt, matching on Participant_Type__c (falling
 * back to the type-blank default record), following the same closed-set
 * CMDT pattern as Deal_Participant_Access_Policy_Resolver.
 */
public without sharing class DealParticipantSlaService {
  /**
   * Computes the Respond_By__c deadline for a new invitation.
   *
   * @param participantType The invited participant's type.
   * @param invitedOn The invitation timestamp to compute the deadline from.
   * @return The computed response deadline.
   */
  public static Datetime computeRespondBy(
    String participantType,
    Datetime invitedOn
  ) {
    Integer hours = resolveResponseHours(participantType);
    return invitedOn.addHours(hours);
  }

  private static Integer resolveResponseHours(String participantType) {
    Deal_Participant_SLA__mdt typeOnlyMatch;

    for (Deal_Participant_SLA__mdt candidate : [
      SELECT Participant_Type__c, Invitation_Response_Hours__c
      FROM Deal_Participant_SLA__mdt
      WHERE Active__c = TRUE
      WITH SYSTEM_MODE
    ]) {
      if (candidate.Participant_Type__c == participantType) {
        return Integer.valueOf(candidate.Invitation_Response_Hours__c);
      }
      if (candidate.Participant_Type__c == null && typeOnlyMatch == null) {
        typeOnlyMatch = candidate;
      }
    }

    if (typeOnlyMatch != null) {
      return Integer.valueOf(typeOnlyMatch.Invitation_Response_Hours__c);
    }

    // No policy configured at all - 72 hours matches the seeded Default
    // record, kept here only as a last-resort fallback if that record is
    // ever deactivated without a replacement.
    return 72;
  }
}
