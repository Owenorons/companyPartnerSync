/*
 * DTO carrying an internal reviewer's approve/reject decision (amount,
 * notes, rejection reason) from the LWC layer into MDFApprovalService.
 */
public with sharing class MDFDecisionDTO {
  @AuraEnabled
  public Id requestId;
  @AuraEnabled
  public String decision;
  @AuraEnabled
  public Decimal approvedAmount;
  @AuraEnabled
  public String decisionNotes;
  @AuraEnabled
  public String rejectionReason;
}
