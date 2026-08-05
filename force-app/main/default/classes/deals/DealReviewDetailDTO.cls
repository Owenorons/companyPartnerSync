/*
 * Full detail shape for the internal review screen: the registration
 * itself, its competing conflicts (List<DealConflictDetailDTO>), computed
 * risk fields, and per-decision permission flags. The internal-review
 * counterpart to DealRegistrationListDTO/DealRegistrationResultDTO, which
 * are the partner-facing shapes for the same underlying record.
 */
public with sharing class DealReviewDetailDTO {
  @AuraEnabled
  public Id dealId { get; set; }
  @AuraEnabled
  public String dealNumber { get; set; }

  @AuraEnabled
  public Id opportunityId { get; set; }
  @AuraEnabled
  public Id customerAccountId { get; set; }
  @AuraEnabled
  public Id partnerAccountId { get; set; }

  @AuraEnabled
  public String customerName { get; set; }
  @AuraEnabled
  public String partnerName { get; set; }

  @AuraEnabled
  public Decimal estimatedRevenue { get; set; }
  @AuraEnabled
  public Date estimatedCloseDate { get; set; }

  @AuraEnabled
  public String businessProblem { get; set; }
  @AuraEnabled
  public String proposedSolution { get; set; }
  @AuraEnabled
  public String implementationTimeline { get; set; }
  @AuraEnabled
  public String notes { get; set; }

  @AuraEnabled
  public String status { get; set; }
  @AuraEnabled
  public String conflictStatus { get; set; }

  @AuraEnabled
  public Date protectionEndDate { get; set; }
  @AuraEnabled
  public Datetime submittedOn { get; set; }

  @AuraEnabled
  public String approvalNotes { get; set; }
  @AuraEnabled
  public String rejectionReason { get; set; }
  @AuraEnabled
  public String conflictResolutionNotes { get; set; }

  @AuraEnabled
  public Decimal riskScore { get; set; }
  @AuraEnabled
  public String riskLevel { get; set; }
  @AuraEnabled
  public String riskSummary { get; set; }
  @AuraEnabled
  public String riskRecommendation { get; set; }

  @AuraEnabled
  public List<DealConflictDetailDTO> conflicts { get; set; }

  // UI gating only — these mirror PartnerPermissionService checks so the
  // LWC can hide/disable actions, but they are not themselves a security
  // boundary. DealReviewService re-asserts the same permissions when a
  // decision is actually submitted.
  @AuraEnabled
  public Boolean canApprove { get; set; }
  @AuraEnabled
  public Boolean canReject { get; set; }
  @AuraEnabled
  public Boolean canResolveConflict { get; set; }
}
