/**
 * DTO for deal conflict information.
 */
public with sharing class DealConflictDTO {
  @AuraEnabled
  public Boolean hasConflict { get; set; }

  @AuraEnabled
  public String conflictStatus { get; set; }

  @AuraEnabled
  public List<Id> conflictingDealIds { get; set; }

  @AuraEnabled
  public String summary { get; set; }
}
