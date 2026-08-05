/*
 * Read-only summary of a single competing registration, embedded in
 * DealReviewDetailDTO.conflicts for the internal review screen. This is
 * distinct from DealConflictDTO, which is the coarse has-conflict/summary
 * result returned to the submitting partner at creation time — this DTO
 * exposes per-conflict detail (partner, customer, revenue, protection date)
 * that only internal reviewers should see.
 */
public with sharing class DealConflictDetailDTO {
  @AuraEnabled
  public Id dealId { get; set; }
  @AuraEnabled
  public String dealNumber { get; set; }

  @AuraEnabled
  public String partnerName { get; set; }
  @AuraEnabled
  public String customerName { get; set; }

  @AuraEnabled
  public Decimal estimatedRevenue { get; set; }
  @AuraEnabled
  public String status { get; set; }
  @AuraEnabled
  public Date protectionEndDate { get; set; }
}
