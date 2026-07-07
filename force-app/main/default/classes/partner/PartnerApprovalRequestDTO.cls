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
