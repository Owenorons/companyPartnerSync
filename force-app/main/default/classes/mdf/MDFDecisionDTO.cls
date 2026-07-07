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
