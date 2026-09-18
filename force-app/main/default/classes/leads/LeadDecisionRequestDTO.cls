/**
 * Request payload for a partner's Accept/Reject decision on an assigned
 * Lead (LeadDecisionService.processDecision) — the gate a lead must pass
 * through before LeadConversionService will touch it.
 */
public with sharing class LeadDecisionRequestDTO {
  /**
   * Id of the Lead the decision applies to.
   */
  @AuraEnabled
  public Id leadId { get; set; }
  /**
   * The partner's decision on the lead (e.g. Accept, Reject).
   */
  @AuraEnabled
  public String decision { get; set; }
  /**
   * Optional notes to attach to the decision.
   */
  @AuraEnabled
  public String notes { get; set; }
}
