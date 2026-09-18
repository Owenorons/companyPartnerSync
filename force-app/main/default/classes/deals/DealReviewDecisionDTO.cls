/**
 * Inbound DTO for an internal reviewer's decision on an already-submitted
 * deal (DealReviewController.processDecision). The decision value drives
 * which branch of DealReviewService.processDecision runs and which fields
 * are required (see DealReviewDomain.validateDecision).
 */
public with sharing class DealReviewDecisionDTO {
  /**
   * Id of the deal registration the decision applies to.
   */
  @AuraEnabled
  public Id dealId { get; set; }

  /**
   * The reviewer's decision.
   *
   * Supported values:
   * Approved
   * Rejected
   * Conflict Resolved
   * Protection Extended
   */
  @AuraEnabled
  public String decision { get; set; }

  /**
   * Notes entered by the reviewer when approving the deal.
   */
  @AuraEnabled
  public String approvalNotes { get; set; }
  /**
   * Reason entered by the reviewer when rejecting the deal; required when decision is 'Rejected'.
   */
  @AuraEnabled
  public String rejectionReason { get; set; }
  /**
   * Notes entered by the reviewer when resolving a conflict on the deal.
   */
  @AuraEnabled
  public String conflictResolutionNotes { get; set; }

  /**
   * Number of days to extend the deal's protection window by; required when decision is 'Protection Extended'.
   */
  @AuraEnabled
  public Integer protectionExtensionDays { get; set; }
}
