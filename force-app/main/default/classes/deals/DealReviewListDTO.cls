/*
 * Row shape for the internal review queue, spanning all partners (see
 * DealReviewSelector.selectReviewQueue). Compare to
 * DealRegistrationListDTO, the equivalent row shape scoped to a single
 * partner's own deals.
 */
public with sharing class DealReviewListDTO {
  @AuraEnabled
  public Id dealId { get; set; }
  @AuraEnabled
  public String dealNumber { get; set; }

  @AuraEnabled
  public String customerName { get; set; }
  @AuraEnabled
  public String partnerName { get; set; }

  @AuraEnabled
  public Decimal estimatedRevenue { get; set; }
  @AuraEnabled
  public Date estimatedCloseDate { get; set; }

  @AuraEnabled
  public String status { get; set; }
  @AuraEnabled
  public String conflictStatus { get; set; }

  @AuraEnabled
  public Date protectionEndDate { get; set; }
  @AuraEnabled
  public Datetime submittedOn { get; set; }
}
