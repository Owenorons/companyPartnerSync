/*
 * DTO carrying an internal reviewer's approve/reject decision (amount,
 * notes, rejection reason) from the LWC layer into MDFApprovalService.
 */
public with sharing class MDFDecisionDTO {
  @AuraEnabled
  public Id requestId { get; set; }
  @AuraEnabled
  public String decision { get; set; }
  @AuraEnabled
  public Decimal approvedAmount { get; set; }
  @AuraEnabled
  public String decisionNotes { get; set; }
  @AuraEnabled
  public String rejectionReason { get; set; }
}
