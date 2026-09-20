/**
 * Read model for a Lead as shown to a partner in the "My Leads" view,
 * covering the assignment/decision lifecycle (Assigned/Accepted/Rejected/
 * Converted) rather than post-conversion Opportunity/Deal data.
 */
public with sharing class LeadDistributionDTO {
  /**
   * Id of the Lead record.
   */
  @AuraEnabled
  public Id leadId { get; set; }
  /**
   * Name of the lead contact.
   */
  @AuraEnabled
  public String leadName { get; set; }
  /**
   * Company name on the lead.
   */
  @AuraEnabled
  public String company { get; set; }
  /**
   * Email address on the lead.
   */
  @AuraEnabled
  public String email { get; set; }
  /**
   * Phone number on the lead.
   */
  @AuraEnabled
  public String phone { get; set; }
  /**
   * Current assignment/decision status of the lead (e.g. Assigned,
   * Accepted, Rejected, Converted).
   */
  @AuraEnabled
  public String status { get; set; }
  /**
   * Date/time the lead was assigned to the partner.
   */
  @AuraEnabled
  public Datetime assignedDate { get; set; }
  /**
   * Date/time by which the partner must act on the lead per its SLA.
   */
  @AuraEnabled
  public Datetime slaDeadline { get; set; }
}
