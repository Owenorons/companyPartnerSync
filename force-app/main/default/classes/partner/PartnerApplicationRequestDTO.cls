/*
 * Inbound submission payload for a brand-new partner application — the raw
 * form data before any record (Account/Contact/Partner_Application__c) has
 * been created for it.
 */
public with sharing class PartnerApplicationRequestDTO {
  @AuraEnabled
  public String companyName;
  @AuraEnabled
  public String businessEmail;
  @AuraEnabled
  public String phone;
  @AuraEnabled
  public String website;
  @AuraEnabled
  public String country;
  @AuraEnabled
  public String region;
  @AuraEnabled
  public String requestedTier;
  @AuraEnabled
  public String partnerType;
  @AuraEnabled
  public String submittedByContactName;
  @AuraEnabled
  public String submittedByEmail;
}
