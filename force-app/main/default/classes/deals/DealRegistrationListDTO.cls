/*
 * Row shape for a partner's own "My Deals" list. Scoped to a single
 * partner's registrations (see DealRegistrationSelector.selectPartnerDeals);
 * compare to DealReviewListDTO, the equivalent row shape used by internal
 * reviewers to see deals across all partners.
 */
public with sharing class DealRegistrationListDTO {
  @AuraEnabled
  public Id dealId;
  @AuraEnabled
  public String dealNumber;

  @AuraEnabled
  public String customerName;
  @AuraEnabled
  public String partnerName;

  @AuraEnabled
  public Decimal dealValue;
  @AuraEnabled
  public String stage;

  @AuraEnabled
  public String status;
  @AuraEnabled
  public String conflictStatus;

  @AuraEnabled
  public Date protectionEndDate;
  @AuraEnabled
  public Datetime createdDate;
}
