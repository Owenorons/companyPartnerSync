/**
 * Request payload for a deal conflict lifecycle command submitted from the
 * UI, describing the target conflict, the action to apply, and its
 * supporting data (reason, assignee, waiver details, etc).
 */
public class DealConflictCommand {
  @AuraEnabled
  public Id conflictId;
  @AuraEnabled
  public String action;
  @AuraEnabled
  public String commandKey;
  @AuraEnabled
  public Integer expectedVersion;
  @AuraEnabled
  public String reason;
  @AuraEnabled
  public Id assigneeId;
  @AuraEnabled
  public Datetime waiverExpiresOn;
  @AuraEnabled
  public String waiverConditions;
  @AuraEnabled
  public String reviewedEvidence;

  /**
   * Validates that the command carries the minimum required fields, throwing
   * a DealLifecycleException when the conflict, action, or a valid command
   * key are missing.
   */
  public void validate() {
    if (conflictId == null || String.isBlank(action)) {
      throw new DealLifecycleException('Conflict and action are required.');
    }
    if (String.isBlank(commandKey) || commandKey.length() > 80) {
      throw new DealLifecycleException(
        'A command key of no more than 80 characters is required.'
      );
    }
  }
}
