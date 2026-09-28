/**
 * Sanitized shape of one Event_DLQ__c row, for
 * PartnerSyncOperationsConsoleController.
 */
public class DeadLetterRowDTO {
  @AuraEnabled
  public Id dlqId;
  @AuraEnabled
  public String eventType;
  @AuraEnabled
  public String status;
  @AuraEnabled
  public Integer retryCount;
  @AuraEnabled
  public Datetime lastRetryOn;
  @AuraEnabled
  public String errorMessage;
  @AuraEnabled
  public Datetime createdOn;
}
