/*
 * Read model for a Lead as shown to a partner in the "My Leads" view,
 * covering the assignment/decision lifecycle (Assigned/Accepted/Rejected/
 * Converted) rather than post-conversion Opportunity/Deal data.
 */
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
