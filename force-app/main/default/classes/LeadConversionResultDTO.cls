public with sharing class LeadConversionResultDTO {
  @AuraEnabled
  public Id leadId;
  @AuraEnabled
  public Id opportunityId;
  @AuraEnabled
  public Id dealRegistrationId;
  @AuraEnabled
  public Id customerAccountId;
  @AuraEnabled
  public Boolean customerAccountCreated;
}
