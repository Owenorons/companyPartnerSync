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
