/*
 * Request payload for routing a Lead to a partner (LeadDistributionService.assignLeadToPartner).
 * This is the initial "assign to a partner queue" step, distinct from
 * LeadConversionRequestDTO which carries the later step of turning an
 * already-accepted lead into an Opportunity/Deal Registration.
 */
public with sharing class LeadAssignmentRequestDTO {
  @AuraEnabled
  public Id leadId;
  @AuraEnabled
  public Id partnerAccountId;
  @AuraEnabled
  public Id partnerContactId;
  @AuraEnabled
  public Id customerAccountId;
  @AuraEnabled
  public Integer slaHoursOverride;
  @AuraEnabled
  public String notes;
}
