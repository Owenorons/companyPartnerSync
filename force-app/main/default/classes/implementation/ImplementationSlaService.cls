/**
 * Resolves Implementation_SLA__mdt (exact-match-with-fallback, same shape
 * as DealParticipantSlaService) and exposes SLA-derived checks. Currently
 * used for handoff-acceptance timing (doc §40.27's Handoff_Acceptance_Hours__c);
 * Target_Start_Days__c/Target_Completion_Days__c/Milestone_Warning_Percentage__c
 * are resolved but not yet consumed - a named follow-up once a concrete
 * UI/workbench need for them exists, matching this codebase's discipline
 * of not building CMDT config without a real consumer.
 */
public without sharing class ImplementationSlaService {
  private static final Integer DEFAULT_HANDOFF_ACCEPTANCE_HOURS = 48;

  /**
   * Indicates whether a submitted handoff has been waiting longer than
   * its resolved SLA's Handoff_Acceptance_Hours__c.
   *
   * @param implementationType The implementation's type, for SLA matching.
   * @param submittedOn When the handoff was submitted.
   * @param asOf The time to evaluate against (pass System.now() in production).
   * @return True if the handoff is overdue for acceptance.
   */
  public static Boolean isHandoffOverdueForAcceptance(
    String implementationType,
    Datetime submittedOn,
    Datetime asOf
  ) {
    if (submittedOn == null) {
      return false;
    }
    Implementation_SLA__mdt sla = resolvePolicy(implementationType);
    Integer hours = sla.Handoff_Acceptance_Hours__c == null
      ? DEFAULT_HANDOFF_ACCEPTANCE_HOURS
      : Integer.valueOf(sla.Handoff_Acceptance_Hours__c);
    return submittedOn.addHours(hours) < asOf;
  }

  private static Implementation_SLA__mdt resolvePolicy(
    String implementationType
  ) {
    Implementation_SLA__mdt exactMatch;
    Implementation_SLA__mdt fallback;
    for (Implementation_SLA__mdt candidate : [
      SELECT
        Implementation_Type__c,
        Target_Start_Days__c,
        Target_Completion_Days__c,
        Handoff_Acceptance_Hours__c,
        Milestone_Warning_Percentage__c
      FROM Implementation_SLA__mdt
      WHERE Active__c = TRUE
      WITH SYSTEM_MODE
    ]) {
      if (candidate.Implementation_Type__c == implementationType) {
        exactMatch = candidate;
        break;
      }
      if (candidate.Implementation_Type__c == null && fallback == null) {
        fallback = candidate;
      }
    }
    Implementation_SLA__mdt resolved = exactMatch != null
      ? exactMatch
      : fallback;
    return resolved == null ? new Implementation_SLA__mdt() : resolved;
  }
}
