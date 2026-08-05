/*
 * Inbound payload from the internal review UI for approving or rejecting a
 * partner application. decision distinguishes approve/reject; the other
 * fields are optional context depending on which path is taken.
 */
public with sharing class PartnerApprovalRequestDTO {
  @AuraEnabled
  public Id applicationId { get; set; }
  @AuraEnabled
  public String decision { get; set; }
  @AuraEnabled
  public String approvalNotes { get; set; }
  @AuraEnabled
  public String rejectionReason { get; set; }
  @AuraEnabled
  public Boolean confirmPotentialMatches { get; set; }
}
