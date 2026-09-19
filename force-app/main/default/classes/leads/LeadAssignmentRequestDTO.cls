/**
 * Request payload for routing a Lead to a partner (LeadDistributionService.assignLeadToPartner).
 * This is the initial "assign to a partner queue" step, distinct from
 * LeadConversionRequestDTO which carries the later step of turning an
 * already-accepted lead into an Opportunity/Deal Registration.
 */
public with sharing class LeadAssignmentRequestDTO {
  /**
   * Id of the Lead being assigned.
   */
  @AuraEnabled
  public Id leadId { get; set; }
  /**
   * Id of the partner Account the lead is being assigned to.
   */
  @AuraEnabled
  public Id partnerAccountId { get; set; }
  /**
   * Id of the partner Contact the lead is being assigned to.
   */
  @AuraEnabled
  public Id partnerContactId { get; set; }
  /**
   * Id of the customer Account associated with the lead, if known.
   */
  @AuraEnabled
  public Id customerAccountId { get; set; }
  /**
   * Optional override for the default SLA response window, in hours.
   */
  @AuraEnabled
  public Integer slaHoursOverride { get; set; }
  /**
   * Optional notes to attach to the assignment.
   */
  @AuraEnabled
  public String notes { get; set; }
}
