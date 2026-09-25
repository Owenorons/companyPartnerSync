/**
 * Internal command payload for a decision on a Partner_Lead_Assignment__c
 * record, consumed by LeadAssignmentCommandService.execute(). Distinct from
 * the Aura-facing LeadDecisionRequestDTO, which is keyed by Lead Id (not
 * assignment Id) and has no expectedVersion - LeadDecisionService resolves
 * both before building this command.
 */
public class LeadAssignmentCommand {
  public Id assignmentId;
  public String action;
  public Integer expectedVersion;
  public String reason;

  /**
   * Validates that the command carries the minimum required fields, throwing
   * a PartnerSyncHandledException when the assignment or action is missing.
   */
  public void validate() {
    if (assignmentId == null || String.isBlank(action)) {
      throw new PartnerSyncHandledException(
        'Lead assignment and action are required.'
      );
    }
  }
}
