public with sharing class LeadDistributionDTO {
  @AuraEnabled
  public Id leadId;
  @AuraEnabled
  public String leadName;
  @AuraEnabled
  public String company;
  @AuraEnabled
  public String email;
  @AuraEnabled
  public String phone;
  @AuraEnabled
  public String status;
  @AuraEnabled
  public Datetime assignedDate;
  @AuraEnabled
  public Datetime slaDeadline;
}
