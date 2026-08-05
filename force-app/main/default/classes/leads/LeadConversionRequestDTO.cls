/*
 * Request payload for converting an already-accepted Lead into an
 * Opportunity + Deal Registration (LeadConversionService.convertLead).
 * Not to be confused with LeadAssignmentRequestDTO, which routes a lead
 * to a partner in the first place.
 */
public with sharing class LeadConversionRequestDTO {
  @AuraEnabled
  public Id leadId { get; set; }
  @AuraEnabled
  public String opportunityName { get; set; }
  @AuraEnabled
  public Decimal estimatedValue { get; set; }
  @AuraEnabled
  public Date estimatedCloseDate { get; set; }
  @AuraEnabled
  public String stageName { get; set; }
  @AuraEnabled
  public String notes { get; set; }
}
