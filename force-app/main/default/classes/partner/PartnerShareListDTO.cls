/*
 * Row shape for the "who has access to this record" list view — one row per
 * active Partner_Record_Share__c grant, denormalized with the partner/
 * grantor names the UI needs so it doesn't have to make follow-up calls.
 */
public with sharing class PartnerShareListDTO {
  @AuraEnabled
  public Id shareId { get; set; }
  @AuraEnabled
  public String targetObject { get; set; }
  @AuraEnabled
  public Id partnerAccountId { get; set; }
  @AuraEnabled
  public String partnerAccountName { get; set; }
  @AuraEnabled
  public String accessLevel { get; set; }
  @AuraEnabled
  public String shareReason { get; set; }
  @AuraEnabled
  public Date expiryDate { get; set; }
  @AuraEnabled
  public String grantedByName { get; set; }
  @AuraEnabled
  public Datetime grantedOn { get; set; }
}
