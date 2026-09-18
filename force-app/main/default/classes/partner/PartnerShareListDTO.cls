/**
 * Row shape for the "who has access to this record" list view — one row per
 * active Partner_Record_Share__c grant, denormalized with the partner/
 * grantor names the UI needs so it doesn't have to make follow-up calls.
 */
public with sharing class PartnerShareListDTO {
  /**
   * Id of the Partner_Record_Share__c grant.
   */
  @AuraEnabled
  public Id shareId { get; set; }
  /**
   * SObject API name of the shared record.
   */
  @AuraEnabled
  public String targetObject { get; set; }
  /**
   * Id of the partner Account the share was granted to.
   */
  @AuraEnabled
  public Id partnerAccountId { get; set; }
  /**
   * Name of the partner Account the share was granted to.
   */
  @AuraEnabled
  public String partnerAccountName { get; set; }
  /**
   * Access level granted (e.g. "Read" or "Edit").
   */
  @AuraEnabled
  public String accessLevel { get; set; }
  /**
   * Reason the share was granted.
   */
  @AuraEnabled
  public String shareReason { get; set; }
  /**
   * Date the granted access expires, if any.
   */
  @AuraEnabled
  public Date expiryDate { get; set; }
  /**
   * Name of the user who granted the share.
   */
  @AuraEnabled
  public String grantedByName { get; set; }
  /**
   * Date and time the share was granted.
   */
  @AuraEnabled
  public Datetime grantedOn { get; set; }
}
