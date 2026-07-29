/*
 * Request payload for converting an already-accepted Lead into an
 * Opportunity + Deal Registration (LeadConversionService.convertLead).
 * Not to be confused with LeadAssignmentRequestDTO, which routes a lead
 * to a partner in the first place.
 */
public with sharing class LeadConversionRequestDTO {
  @AuraEnabled
  public Id leadId;
  @AuraEnabled
  public String opportunityName;
  @AuraEnabled
  public Decimal estimatedValue;
  @AuraEnabled
  public Date estimatedCloseDate;
  @AuraEnabled
  public String stageName;
  @AuraEnabled
  public String notes;
}
