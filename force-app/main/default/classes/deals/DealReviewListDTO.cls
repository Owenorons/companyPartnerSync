/**
 * Row shape for the internal review queue, spanning all partners (see
 * DealReviewSelector.selectReviewQueue). Compare to
 * DealRegistrationListDTO, the equivalent row shape scoped to a single
 * partner's own deals.
 */
public with sharing class DealReviewListDTO {
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
}
