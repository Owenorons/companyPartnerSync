/**
 * Partner-safe summary of a Deal_Implementation__c row (no
 * External_Project_System__c/External_Project_Id__c/External_Sync_Status__c
 * forward-compatibility fields - Adaptation #7, no adapter exists to make
 * them meaningful yet), for both the partner-facing implementation
 * workspace and the internal implementation workbench queues.
 */
public class ImplementationSummaryDTO {
  @AuraEnabled
  public Id implementationId;
  @AuraEnabled
  public Id dealId;
  @AuraEnabled
  public String customerName;
  @AuraEnabled
  public String partnerName;
  @AuraEnabled
  public String implementationType;
  @AuraEnabled
  public String status;
  @AuraEnabled
  public String health;
  @AuraEnabled
  public Date plannedStartDate;
  @AuraEnabled
  public Date plannedCompletionDate;
  @AuraEnabled
  public Date actualStartDate;
  @AuraEnabled
  public Date actualCompletionDate;
  @AuraEnabled
  public Integer versionNumber;
}
