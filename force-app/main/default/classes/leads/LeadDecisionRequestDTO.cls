/*
 * Request payload for a partner's Accept/Reject decision on an assigned
 * Lead (LeadDecisionService.processDecision) — the gate a lead must pass
 * through before LeadConversionService will touch it.
 */
public with sharing class LeadDecisionRequestDTO {
  @AuraEnabled
  public Id leadId;
  @AuraEnabled
  public String decision;
  @AuraEnabled
  public String notes;
}
