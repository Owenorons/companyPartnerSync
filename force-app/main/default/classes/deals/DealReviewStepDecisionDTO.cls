/**
 * Aura-safe request payload for a deal review step action, mirroring the
 * internal DealReviewCommand DTO that DealReviewCommandService.execute()
 * actually consumes.
 */
public with sharing class DealReviewStepDecisionDTO {
  /**
   * Id of the deal review step being acted on.
   */
  @AuraEnabled
  public Id reviewId { get; set; }
  /**
   * The action: 'Start', 'Complete', 'Request Info', 'Resume', 'Reassign',
   * 'Recuse', 'Waive', 'Escalate', or 'Cancel'.
   */
  @AuraEnabled
  public String action { get; set; }
  /**
   * Outcome. Required for 'Complete'.
   */
  @AuraEnabled
  public String outcome { get; set; }
  /**
   * Reason. Required for 'Recuse'/'Waive'.
   */
  @AuraEnabled
  public String reason { get; set; }
  /**
   * New assignee. Required for 'Reassign'.
   */
  @AuraEnabled
  public Id assigneeId { get; set; }
  /**
   * Question to the deal's owner/partner. Required for 'Request Info'.
   */
  @AuraEnabled
  public String question { get; set; }
  /**
   * Who the information request is addressed to. Used with 'Request Info'.
   */
  @AuraEnabled
  public String audience { get; set; }
  /**
   * What evidence is required to satisfy the information request. Used with 'Request Info'.
   */
  @AuraEnabled
  public String evidenceRequirement { get; set; }
  /**
   * When the information request is due. Used with 'Request Info'.
   */
  @AuraEnabled
  public Datetime dueOn { get; set; }
  /**
   * Expected Version_Number__c of the step, for optimistic concurrency.
   */
  @AuraEnabled
  public Integer expectedVersion { get; set; }
}
