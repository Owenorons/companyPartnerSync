/*
 * Row shape for the "who has access to this record" list view — one row per
 * active Partner_Record_Share__c grant, denormalized with the partner/
 * grantor names the UI needs so it doesn't have to make follow-up calls.
 */
public with sharing class PartnerShareListDTO {
  @AuraEnabled
  public Id shareId;
  @AuraEnabled
  public String targetObject;
  @AuraEnabled
  public Id partnerAccountId;
  @AuraEnabled
  public String partnerAccountName;
  @AuraEnabled
  public String accessLevel;
  @AuraEnabled
  public String shareReason;
  @AuraEnabled
  public Date expiryDate;
  @AuraEnabled
  public String grantedByName;
  @AuraEnabled
  public Datetime grantedOn;
}
