/**
 * Result of executing a deal conflict lifecycle command, returned to the UI
 * and cached for idempotent replay of duplicate command keys.
 */
public class DealConflictCommandResult {
  @AuraEnabled
  public Boolean completed;
  @AuraEnabled
  public Boolean duplicateCommand;
  @AuraEnabled
  public Id conflictId;
  @AuraEnabled
  public String previousStatus;
  @AuraEnabled
  public String newStatus;
  @AuraEnabled
  public Integer resultingVersion;
  @AuraEnabled
  public Id eventId;
}
