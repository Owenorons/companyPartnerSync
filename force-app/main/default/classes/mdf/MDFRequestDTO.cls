public with sharing class MDFRequestDTO {
  @AuraEnabled
  public String requestType;
  @AuraEnabled
  public String campaignName;
  @AuraEnabled
  public String campaignDescription;
  @AuraEnabled
  public Decimal requestedAmount;
  @AuraEnabled
  public Date startDate;
  @AuraEnabled
  public Date endDate;
  @AuraEnabled
  public Id relatedDealId;
  @AuraEnabled
  public Decimal roiTarget;
}
