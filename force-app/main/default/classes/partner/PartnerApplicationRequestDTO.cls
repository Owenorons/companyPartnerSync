/*
 * Inbound submission payload for a brand-new partner application — the raw
 * form data before any record (Account/Contact/Partner_Application__c) has
 * been created for it.
 */
public with sharing class PartnerApplicationRequestDTO {
  @AuraEnabled
  public String companyName { get; set; }
  @AuraEnabled
  public String businessEmail { get; set; }
  @AuraEnabled
  public String phone { get; set; }
  @AuraEnabled
  public String website { get; set; }
  @AuraEnabled
  public String country { get; set; }
  @AuraEnabled
  public String region { get; set; }
  @AuraEnabled
  public String requestedTier { get; set; }
  @AuraEnabled
  public String partnerType { get; set; }
  @AuraEnabled
  public String submittedByContactName { get; set; }
  @AuraEnabled
  public String submittedByEmail { get; set; }
}
