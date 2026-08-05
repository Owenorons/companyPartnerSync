/*
 * Row shape for a partner's own "My Deals" list. Scoped to a single
 * partner's registrations (see DealRegistrationSelector.selectPartnerDeals);
 * compare to DealReviewListDTO, the equivalent row shape used by internal
 * reviewers to see deals across all partners.
 */
public with sharing class DealRegistrationListDTO {
  @AuraEnabled
  public Id dealId { get; set; }
  @AuraEnabled
  public String dealNumber { get; set; }

  @AuraEnabled
  public String customerName { get; set; }
  @AuraEnabled
  public String partnerName { get; set; }

  @AuraEnabled
  public Decimal dealValue { get; set; }
  @AuraEnabled
  public String stage { get; set; }

  @AuraEnabled
  public String status { get; set; }
  @AuraEnabled
  public String conflictStatus { get; set; }

  @AuraEnabled
  public Date protectionEndDate { get; set; }
  @AuraEnabled
  public Datetime createdDate { get; set; }
}
