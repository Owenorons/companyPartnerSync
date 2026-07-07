public with sharing class CustomerRevenueDTO {
  @AuraEnabled
  public Id customerAccountId;
  @AuraEnabled
  public String customerName;

  @AuraEnabled
  public Id partnerAccountId;
  @AuraEnabled
  public String partnerName;

  @AuraEnabled
  public Decimal revenue;
  @AuraEnabled
  public Integer opportunityCount;
}
