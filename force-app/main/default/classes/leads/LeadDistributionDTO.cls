/*
 * Read model for a Lead as shown to a partner in the "My Leads" view,
 * covering the assignment/decision lifecycle (Assigned/Accepted/Rejected/
 * Converted) rather than post-conversion Opportunity/Deal data.
 */
public with sharing class LeadDistributionDTO {
  @AuraEnabled
  public Id leadId { get; set; }
  @AuraEnabled
  public String leadName { get; set; }
  @AuraEnabled
  public String company { get; set; }
  @AuraEnabled
  public String email { get; set; }
  @AuraEnabled
  public String phone { get; set; }
  @AuraEnabled
  public String status { get; set; }
  @AuraEnabled
  public Datetime assignedDate { get; set; }
  @AuraEnabled
  public Datetime slaDeadline { get; set; }
}
