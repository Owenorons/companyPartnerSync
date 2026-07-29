/*
 * Inbound DTO for an internal reviewer's decision on an already-submitted
 * deal (DealReviewController.processDecision). The decision value drives
 * which branch of DealReviewService.processDecision runs and which fields
 * are required (see DealReviewDomain.validateDecision).
 */
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
