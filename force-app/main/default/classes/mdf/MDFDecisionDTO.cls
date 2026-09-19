/**
 * DTO carrying an internal reviewer's approve/reject decision (amount,
 * notes, rejection reason) from the LWC layer into MDFApprovalService.
 */
public with sharing class MDFDecisionDTO {
  /**
   * Id of the MDF_Request__c record being decided.
   */
  @AuraEnabled
  public Id requestId { get; set; }
  /**
   * The reviewer's decision: 'Approved' or 'Rejected'.
   */
  @AuraEnabled
  public String decision { get; set; }
  /**
   * Amount approved, required when decision is 'Approved'.
   */
  @AuraEnabled
  public Decimal approvedAmount { get; set; }
  /**
   * Optional free-text notes from the reviewer about the decision.
   */
  @AuraEnabled
  public String decisionNotes { get; set; }
  /**
   * Reason for rejection, required when decision is 'Rejected'.
   */
  @AuraEnabled
  public String rejectionReason { get; set; }
}
