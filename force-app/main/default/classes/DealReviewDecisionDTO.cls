public with sharing class DealReviewDecisionDTO {
  @AuraEnabled
  public Id dealId;

  /*
   * Supported values:
   * Approved
   * Rejected
   * Conflict Resolved
   * Protection Extended
   */
  @AuraEnabled
  public String decision;

  @AuraEnabled
  public String approvalNotes;
  @AuraEnabled
  public String rejectionReason;
  @AuraEnabled
  public String conflictResolutionNotes;

  @AuraEnabled
  public Integer protectionExtensionDays;
}
