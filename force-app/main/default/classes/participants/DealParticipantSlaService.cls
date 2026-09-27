/**
 * Resolves a co-sell invitation's response deadline and warning threshold
 * from Deal_Participant_SLA__mdt, matching on Participant_Type__c (falling
 * back to the type-blank default record), following the same closed-set
 * CMDT pattern as Deal_Participant_Access_Policy_Resolver. Deliberately
 * calendar-time only (no business-hours calendar) - see
 * docs/deal-participant-management-review.md for why.
 */
public without sharing class DealParticipantSlaService {
  private static final Integer DEFAULT_RESPONSE_HOURS = 72;
  private static final Integer DEFAULT_WARNING_PERCENTAGE = 75;

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
    return invitedOn.addHours(resolvePolicy(participantType).responseHours);
  }

  /**
   * Indicates whether an invitation has crossed its SLA warning threshold
   * (elapsed time / total window >= Warning_Percentage__c) without yet
   * being overdue.
   *
   * @param participantType The participant's type, to resolve the applicable policy.
   * @param invitedOn The invitation timestamp.
   * @param respondBy The invitation's response deadline.
   * @param asOf The timestamp to evaluate risk as of (typically System.now()).
   * @return True if the invitation is at risk but not yet overdue.
   */
  public static Boolean isAtRisk(
    String participantType,
    Datetime invitedOn,
    Datetime respondBy,
    Datetime asOf
  ) {
    if (invitedOn == null || respondBy == null || asOf >= respondBy) {
      return false;
    }

    Long totalWindowMs = respondBy.getTime() - invitedOn.getTime();
    if (totalWindowMs <= 0) {
      return false;
    }

    Long elapsedMs = asOf.getTime() - invitedOn.getTime();
    Decimal elapsedPercentage =
      (Decimal.valueOf(elapsedMs) * 100) / Decimal.valueOf(totalWindowMs);

    return elapsedPercentage >=
      resolvePolicy(participantType).warningPercentage;
  }

  private static Policy resolvePolicy(String participantType) {
    Deal_Participant_SLA__mdt typeOnlyMatch;

    for (Deal_Participant_SLA__mdt candidate : [
      SELECT
        Participant_Type__c,
        Invitation_Response_Hours__c,
        Warning_Percentage__c
      FROM Deal_Participant_SLA__mdt
      WHERE Active__c = TRUE
      WITH SYSTEM_MODE
    ]) {
      if (candidate.Participant_Type__c == participantType) {
        return new Policy(candidate);
      }
      if (candidate.Participant_Type__c == null && typeOnlyMatch == null) {
        typeOnlyMatch = candidate;
      }
    }

    if (typeOnlyMatch != null) {
      return new Policy(typeOnlyMatch);
    }

    // No policy configured at all - these defaults match the seeded
    // Default record, kept here only as a last-resort fallback if that
    // record is ever deactivated without a replacement.
    return new Policy(DEFAULT_RESPONSE_HOURS, DEFAULT_WARNING_PERCENTAGE);
  }

  private class Policy {
    Integer responseHours;
    Integer warningPercentage;

    Policy(Deal_Participant_SLA__mdt record) {
      this.responseHours = Integer.valueOf(record.Invitation_Response_Hours__c);
      this.warningPercentage = record.Warning_Percentage__c == null
        ? DEFAULT_WARNING_PERCENTAGE
        : Integer.valueOf(record.Warning_Percentage__c);
    }

    Policy(Integer responseHours, Integer warningPercentage) {
      this.responseHours = responseHours;
      this.warningPercentage = warningPercentage;
    }
  }
}
