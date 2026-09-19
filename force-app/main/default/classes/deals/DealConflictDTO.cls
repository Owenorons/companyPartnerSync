/**
 * DTO for deal conflict information.
 */
public with sharing class DealConflictDTO {
  /**
   * Whether a competing registration was found for the deal.
   */
  @AuraEnabled
  public Boolean hasConflict { get; set; }

  /**
   * Conflict status assigned to the deal as a result of the conflict check.
   */
  @AuraEnabled
  public String conflictStatus { get; set; }

  /**
   * Ids of the competing deal registrations found, if any.
   */
  @AuraEnabled
  public List<Id> conflictingDealIds { get; set; }

  /**
   * Human-readable summary of the conflict outcome.
   */
  @AuraEnabled
  public String summary { get; set; }
}
