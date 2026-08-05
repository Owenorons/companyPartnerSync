/*
 * Inbound DTO for an internal reviewer's decision on an already-submitted
 * deal (DealReviewController.processDecision). The decision value drives
 * which branch of DealReviewService.processDecision runs and which fields
 * are required (see DealReviewDomain.validateDecision).
 */
public with sharing class DealReviewDecisionDTO {
  @AuraEnabled
  public Id dealId { get; set; }

  /*
   * Supported values:
   * Approved
   * Rejected
   * Conflict Resolved
   * Protection Extended
   */
  @AuraEnabled
  public String decision { get; set; }

  @AuraEnabled
  public String approvalNotes { get; set; }
  @AuraEnabled
  public String rejectionReason { get; set; }
  @AuraEnabled
  public String conflictResolutionNotes { get; set; }

  @AuraEnabled
  public Integer protectionExtensionDays { get; set; }
}
