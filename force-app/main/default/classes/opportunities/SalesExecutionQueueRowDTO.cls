/**
 * Shared row shape for the internal Sales Execution Workbench's 4 queue
 * views (Opportunity Pending Link, Reapproval Required, Orphaned
 * Relationships, Recently Closed) - internal-only, so unlike
 * SalesProgressDTO it can carry Status__c/Lifecycle_Health__c freely.
 */
public class SalesExecutionQueueRowDTO {
  @AuraEnabled
  public Id dealId;
  @AuraEnabled
  public String customerName;
  @AuraEnabled
  public String partnerName;
  @AuraEnabled
  public String status;
  @AuraEnabled
  public String stage;
}
