/*
 * Inbound request to grant a partner account access to a single record
 * (Deal Registration or MDF Request today — see PartnerShareService). Not
 * the same shape as the registry record itself; this is only what the
 * caller supplies before defaults (Active__c, Granted_By__c, etc.) are set.
 */
public with sharing class PartnerShareDTO {
  @AuraEnabled
  public Id targetRecordId;
  @AuraEnabled
  public String targetObject;
  @AuraEnabled
  public Id partnerAccountId;
  @AuraEnabled
  public String accessLevel;
  @AuraEnabled
  public String shareReason;
  @AuraEnabled
  public Date expiryDate;
}
