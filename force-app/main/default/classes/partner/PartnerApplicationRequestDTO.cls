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
