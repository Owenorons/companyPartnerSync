/*
 * Result payload returned by LeadConversionService.convertLead(), giving the
 * LWC layer the Ids of every record produced by the conversion (Opportunity,
 * Deal Registration, and the customer Account, which may be newly created).
 */
public with sharing class LeadConversionResultDTO {
  @AuraEnabled
  public Id leadId { get; set; }
  @AuraEnabled
  public Id opportunityId { get; set; }
  @AuraEnabled
  public Id dealRegistrationId { get; set; }
  @AuraEnabled
  public Id customerAccountId { get; set; }
  @AuraEnabled
  public Boolean customerAccountCreated { get; set; }
}
