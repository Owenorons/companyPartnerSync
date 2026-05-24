public with sharing class DealConflictDetailDTO {
  @AuraEnabled
  public Id dealId;
  @AuraEnabled
  public String dealNumber;

  @AuraEnabled
  public String partnerName;
  @AuraEnabled
  public String customerName;

  @AuraEnabled
  public Decimal estimatedRevenue;
  @AuraEnabled
  public String status;
  @AuraEnabled
  public Date protectionEndDate;
}
