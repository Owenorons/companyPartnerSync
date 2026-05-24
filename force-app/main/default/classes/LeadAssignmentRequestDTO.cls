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
