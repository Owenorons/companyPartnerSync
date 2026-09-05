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
