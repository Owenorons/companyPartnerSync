public with sharing class LeadDecisionRequestDTO {
  @AuraEnabled
  public Id leadId;
  @AuraEnabled
  public String decision;
  @AuraEnabled
  public String notes;
}
