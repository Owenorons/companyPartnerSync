/*
 * Inbound payload from the internal review UI for approving or rejecting a
 * partner application. decision distinguishes approve/reject; the other
 * fields are optional context depending on which path is taken.
 */
public with sharing class PartnerApprovalRequestDTO {
  @AuraEnabled
  public Id applicationId;
  @AuraEnabled
  public String decision;
  @AuraEnabled
  public String approvalNotes;
  @AuraEnabled
  public String rejectionReason;
}
