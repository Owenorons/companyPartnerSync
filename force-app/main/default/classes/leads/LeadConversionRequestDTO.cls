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
