/**
 * Inbound DTO for a reviewer's decision on a single partner risk-approval
 * step (PartnerRiskApprovalController.decideStep).
 */
public with sharing class PartnerApprovalStepDecisionDTO {
  /**
   * Id of the Partner_Approval_Step__c the decision applies to.
   */
  @AuraEnabled
  public Id stepId { get; set; }

  /**
   * The reviewer's decision.
   *
   * Supported values:
   * Approved
   * Conditionally Approved
   * Rejected
   * More Information Required
   */
  @AuraEnabled
  public String decision { get; set; }

  /**
   * Reason for the decision; required unless decision is 'Approved'.
   */
  @AuraEnabled
  public String reason { get; set; }
}
