/*
 * Full detail shape for the internal review screen: the registration
 * itself, its competing conflicts (List<DealConflictDetailDTO>), computed
 * risk fields, and per-decision permission flags. The internal-review
 * counterpart to DealRegistrationListDTO/DealRegistrationResultDTO, which
 * are the partner-facing shapes for the same underlying record.
 */
public with sharing class DealReviewDetailDTO {
  @AuraEnabled
  public Id dealId;
  @AuraEnabled
  public String dealNumber;

  @AuraEnabled
  public Id opportunityId;
  @AuraEnabled
  public Id customerAccountId;
  @AuraEnabled
  public Id partnerAccountId;

  @AuraEnabled
  public String customerName;
  @AuraEnabled
  public String partnerName;

  @AuraEnabled
  public Decimal estimatedRevenue;
  @AuraEnabled
  public Date estimatedCloseDate;

  @AuraEnabled
  public String businessProblem;
  @AuraEnabled
  public String proposedSolution;
  @AuraEnabled
  public String implementationTimeline;
  @AuraEnabled
  public String notes;

  @AuraEnabled
  public String status;
  @AuraEnabled
  public String conflictStatus;

  @AuraEnabled
  public Date protectionEndDate;
  @AuraEnabled
  public Datetime submittedOn;

  @AuraEnabled
  public String approvalNotes;
  @AuraEnabled
  public String rejectionReason;
  @AuraEnabled
  public String conflictResolutionNotes;

  @AuraEnabled
  public Decimal riskScore;
  @AuraEnabled
  public String riskLevel;
  @AuraEnabled
  public String riskSummary;
  @AuraEnabled
  public String riskRecommendation;

  @AuraEnabled
  public List<DealConflictDetailDTO> conflicts;

  // UI gating only — these mirror PartnerPermissionService checks so the
  // LWC can hide/disable actions, but they are not themselves a security
  // boundary. DealReviewService re-asserts the same permissions when a
  // decision is actually submitted.
  @AuraEnabled
  public Boolean canApprove;
  @AuraEnabled
  public Boolean canReject;
  @AuraEnabled
  public Boolean canResolveConflict;
}
