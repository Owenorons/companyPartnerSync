public with sharing class DealConflictDTO {
  @AuraEnabled
  public Boolean hasConflict;

  @AuraEnabled
  public String conflictStatus;

  @AuraEnabled
  public List<Id> conflictingDealIds;

  @AuraEnabled
  public String summary;
}
