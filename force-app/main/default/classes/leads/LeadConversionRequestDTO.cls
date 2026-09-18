/**
 * Request payload for converting an already-accepted Lead into an
 * Opportunity + Deal Registration (LeadConversionService.convertLead).
 * Not to be confused with LeadAssignmentRequestDTO, which routes a lead
 * to a partner in the first place.
 */
public with sharing class LeadConversionRequestDTO {
  /**
   * Id of the Lead being converted.
   */
  @AuraEnabled
  public Id leadId { get; set; }
  /**
   * Name to give the Opportunity created by the conversion.
   */
  @AuraEnabled
  public String opportunityName { get; set; }
  /**
   * Estimated value of the resulting Opportunity.
   */
  @AuraEnabled
  public Decimal estimatedValue { get; set; }
  /**
   * Estimated close date of the resulting Opportunity.
   */
  @AuraEnabled
  public Date estimatedCloseDate { get; set; }
  /**
   * Sales stage to set on the resulting Opportunity.
   */
  @AuraEnabled
  public String stageName { get; set; }
  /**
   * Optional notes to attach to the conversion.
   */
  @AuraEnabled
  public String notes { get; set; }
}
