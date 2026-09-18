/**
 * Inbound payload from the internal review UI for approving or rejecting a
 * partner application. decision distinguishes approve/reject; the other
 * fields are optional context depending on which path is taken.
 */
public with sharing class PartnerApprovalRequestDTO {
  /**
   * Id of the Partner_Application__c being decided on.
   */
  @AuraEnabled
  public Id applicationId { get; set; }
  /**
   * The reviewer's decision (e.g. "Approve" or "Reject").
   */
  @AuraEnabled
  public String decision { get; set; }
  /**
   * Optional notes recorded when approving the application.
   */
  @AuraEnabled
  public String approvalNotes { get; set; }
  /**
   * Reason recorded when rejecting the application.
   */
  @AuraEnabled
  public String rejectionReason { get; set; }
  /**
   * Whether the reviewer has confirmed the application should proceed
   * despite any potential duplicate matches that were flagged.
   */
  @AuraEnabled
  public Boolean confirmPotentialMatches { get; set; }
}
