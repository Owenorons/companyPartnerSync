public with sharing class DealReviewListDTO {
  @AuraEnabled
  public Id dealId;
  @AuraEnabled
  public String dealNumber;

  @AuraEnabled
  public String customerName;
  @AuraEnabled
  public String partnerName;

  @AuraEnabled
  public Decimal estimatedRevenue;
  @AuraEnabled
  public Date estimatedCloseDate;

  @AuraEnabled
  public String status;
  @AuraEnabled
  public String conflictStatus;

  @AuraEnabled
  public Date protectionEndDate;
  @AuraEnabled
  public Datetime submittedOn;
}
