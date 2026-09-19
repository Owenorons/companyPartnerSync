/**
 * Full detail shape for the internal review screen: the registration
 * itself, its competing conflicts (List<DealConflictDetailDTO>), computed
 * risk fields, and per-decision permission flags. The internal-review
 * counterpart to DealRegistrationListDTO/DealRegistrationResultDTO, which
 * are the partner-facing shapes for the same underlying record.
 */
public with sharing class DealReviewDetailDTO {
  /**
   * Id of the deal registration record.
   */
  @AuraEnabled
  public Id dealId { get; set; }
  /**
   * Display name/number of the deal registration record.
   */
  @AuraEnabled
  public String dealNumber { get; set; }

  /**
   * Id of the opportunity the deal registration was created from.
   */
  @AuraEnabled
  public Id opportunityId { get; set; }
  /**
   * Id of the customer account associated with the deal.
   */
  @AuraEnabled
  public Id customerAccountId { get; set; }
  /**
   * Id of the partner account that submitted the deal.
   */
  @AuraEnabled
  public Id partnerAccountId { get; set; }

  /**
   * Name of the customer account associated with the deal.
   */
  @AuraEnabled
  public String customerName { get; set; }
  /**
   * Name of the partner account that submitted the deal.
   */
  @AuraEnabled
  public String partnerName { get; set; }

  /**
   * Estimated revenue value of the deal.
   */
  @AuraEnabled
  public Decimal estimatedRevenue { get; set; }
  /**
   * Estimated close date of the underlying opportunity.
   */
  @AuraEnabled
  public Date estimatedCloseDate { get; set; }

  /**
   * Business problem the partner described when submitting the deal.
   */
  @AuraEnabled
  public String businessProblem { get; set; }
  /**
   * Proposed solution the partner described when submitting the deal.
   */
  @AuraEnabled
  public String proposedSolution { get; set; }
  /**
   * Implementation timeline the partner described when submitting the deal.
   */
  @AuraEnabled
  public String implementationTimeline { get; set; }
  /**
   * Free-text notes captured on the deal registration.
   */
  @AuraEnabled
  public String notes { get; set; }

  /**
   * Current status of the deal registration (e.g. Submitted, Approved, Rejected).
   */
  @AuraEnabled
  public String status { get; set; }
  /**
   * Current conflict status of the deal registration.
   */
  @AuraEnabled
  public String conflictStatus { get; set; }

  /**
   * Date the deal's protection window ends, if any.
   */
  @AuraEnabled
  public Date protectionEndDate { get; set; }
  /**
   * Date/time the deal registration was submitted for review.
   */
  @AuraEnabled
  public Datetime submittedOn { get; set; }

  /**
   * Notes entered by the reviewer when approving the deal.
   */
  @AuraEnabled
  public String approvalNotes { get; set; }
  /**
   * Reason entered by the reviewer when rejecting the deal.
   */
  @AuraEnabled
  public String rejectionReason { get; set; }
  /**
   * Notes entered by the reviewer when resolving a conflict on the deal.
   */
  @AuraEnabled
  public String conflictResolutionNotes { get; set; }

  /**
   * Computed risk score for the deal, from DealRiskScoringService.
   */
  @AuraEnabled
  public Decimal riskScore { get; set; }
  /**
   * Computed risk level label for the deal, from DealRiskScoringService.
   */
  @AuraEnabled
  public String riskLevel { get; set; }
  /**
   * Computed human-readable risk summary for the deal, from DealRiskScoringService.
   */
  @AuraEnabled
  public String riskSummary { get; set; }
  /**
   * Computed risk-based recommendation for the deal, from DealRiskScoringService.
   */
  @AuraEnabled
  public String riskRecommendation { get; set; }

  /**
   * Competing registrations found for the same customer account.
   */
  @AuraEnabled
  public List<DealConflictDetailDTO> conflicts { get; set; }

  // UI gating only — these mirror PartnerPermissionService checks so the
  // LWC can hide/disable actions, but they are not themselves a security
  // boundary. DealReviewService re-asserts the same permissions when a
  // decision is actually submitted.
  /**
   * Whether the running user is permitted to approve this deal, per PartnerPermissionService.
   */
  @AuraEnabled
  public Boolean canApprove { get; set; }
  /**
   * Whether the running user is permitted to reject this deal, per PartnerPermissionService.
   */
  @AuraEnabled
  public Boolean canReject { get; set; }
  /**
   * Whether the running user is permitted to resolve this deal's conflict, per PartnerPermissionService.
   */
  @AuraEnabled
  public Boolean canResolveConflict { get; set; }
}
