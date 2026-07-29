/*
 * Result payload returned by LeadConversionService.convertLead(), giving the
 * LWC layer the Ids of every record produced by the conversion (Opportunity,
 * Deal Registration, and the customer Account, which may be newly created).
 */
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
