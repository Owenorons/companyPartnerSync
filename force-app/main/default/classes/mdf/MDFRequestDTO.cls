/*
 * DTO carrying a partner's new MDF request from the LWC layer into
 * MDFService/MDFDomain for validation and record creation.
 */
public with sharing class MDFRequestDTO {
  @AuraEnabled
  public String requestType { get; set; }
  @AuraEnabled
  public String campaignName { get; set; }
  @AuraEnabled
  public String campaignDescription { get; set; }
  @AuraEnabled
  public Decimal requestedAmount { get; set; }
  @AuraEnabled
  public Date startDate { get; set; }
  @AuraEnabled
  public Date endDate { get; set; }
  @AuraEnabled
  public Id relatedDealId { get; set; }
  @AuraEnabled
  public Decimal roiTarget { get; set; }
}
