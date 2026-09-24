/**
 * Aura-safe request payload for an approval step decision, mirroring the
 * internal DealApprovalCommand DTO that DealApprovalCommandService.complete()
 * actually consumes.
 */
public with sharing class DealApprovalDecisionDTO {
  /**
   * Id of the approval step being decided.
   */
  @AuraEnabled
  public Id approvalId { get; set; }
  /**
   * The decision: 'Approved', 'Approved with Conditions', 'Rejected', or 'Returned'.
   */
  @AuraEnabled
  public String decision { get; set; }
  /**
   * Reason for the decision. Required for 'Rejected'/'Returned'.
   */
  @AuraEnabled
  public String reason { get; set; }
  /**
   * Expected Version_Number__c of the step, for optimistic concurrency.
   */
  @AuraEnabled
  public Integer expectedVersion { get; set; }
  /**
   * Condition type. Required for 'Approved with Conditions'.
   */
  @AuraEnabled
  public String conditionType { get; set; }
  /**
   * Condition description. Required for 'Approved with Conditions'.
   */
  @AuraEnabled
  public String conditionDescription { get; set; }
}
