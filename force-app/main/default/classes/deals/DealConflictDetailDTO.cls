/**
 * Read-only summary of a single competing registration, embedded in
 * DealReviewDetailDTO.conflicts for the internal review screen. This is
 * distinct from DealConflictDTO, which is the coarse has-conflict/summary
 * result returned to the submitting partner at creation time — this DTO
 * exposes per-conflict detail (partner, customer, revenue, protection date)
 * that only internal reviewers should see.
 */
public with sharing class DealConflictDetailDTO {
  /**
   * Id of the competing deal registration record.
   */
  @AuraEnabled
  public Id dealId { get; set; }
  /**
   * Display name/number of the competing deal registration record.
   */
  @AuraEnabled
  public String dealNumber { get; set; }

  /**
   * Name of the partner account that submitted the competing deal.
   */
  @AuraEnabled
  public String partnerName { get; set; }
  /**
   * Name of the customer account associated with the competing deal.
   */
  @AuraEnabled
  public String customerName { get; set; }

  /**
   * Estimated revenue value of the competing deal.
   */
  @AuraEnabled
  public Decimal estimatedRevenue { get; set; }
  /**
   * Current status of the competing deal registration.
   */
  @AuraEnabled
  public String status { get; set; }
  /**
   * Date the competing deal's protection window ends, if any.
   */
  @AuraEnabled
  public Date protectionEndDate { get; set; }
}
