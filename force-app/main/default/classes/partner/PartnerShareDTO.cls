/**
 * Inbound request to grant a partner account access to a single record
 * (Deal Registration or MDF Request today — see PartnerShareService). Not
 * the same shape as the registry record itself; this is only what the
 * caller supplies before defaults (Active__c, Granted_By__c, etc.) are set.
 */
public with sharing class PartnerShareDTO {
  /**
   * Id of the record being shared with the partner account.
   */
  @AuraEnabled
  public Id targetRecordId { get; set; }
  /**
   * SObject API name of the shared record (e.g. "Deal_Registration__c").
   */
  @AuraEnabled
  public String targetObject { get; set; }
  /**
   * Id of the partner Account being granted access.
   */
  @AuraEnabled
  public Id partnerAccountId { get; set; }
  /**
   * Requested access level for the share (e.g. "Read" or "Edit").
   */
  @AuraEnabled
  public String accessLevel { get; set; }
  /**
   * Reason given for granting this share.
   */
  @AuraEnabled
  public String shareReason { get; set; }
  /**
   * Date the granted access should expire, if any.
   */
  @AuraEnabled
  public Date expiryDate { get; set; }
}
