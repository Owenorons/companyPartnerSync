/*
 * Request payload for routing a Lead to a partner (LeadDistributionService.assignLeadToPartner).
 * This is the initial "assign to a partner queue" step, distinct from
 * LeadConversionRequestDTO which carries the later step of turning an
 * already-accepted lead into an Opportunity/Deal Registration.
 */
public with sharing class LeadAssignmentRequestDTO {
  @AuraEnabled
  public Id leadId { get; set; }
  @AuraEnabled
  public Id partnerAccountId { get; set; }
  @AuraEnabled
  public Id partnerContactId { get; set; }
  @AuraEnabled
  public Id customerAccountId { get; set; }
  @AuraEnabled
  public Integer slaHoursOverride { get; set; }
  @AuraEnabled
  public String notes { get; set; }
}
