/**
 * Row shape for the internal risk-approval queue, spanning all partners
 * (see PartnerRiskApprovalService.getApprovalQueue).
 */
public with sharing class PartnerApprovalStepListDTO {
  /**
   * Id of the approval step record.
   */
  @AuraEnabled
  public Id stepId { get; set; }
  /**
   * Id of the owning approval plan.
   */
  @AuraEnabled
  public Id planId { get; set; }
  /**
   * Id of the owning onboarding aggregate.
   */
  @AuraEnabled
  public Id onboardingId { get; set; }

  /**
   * Name of the partner account the onboarding belongs to.
   */
  @AuraEnabled
  public String partnerName { get; set; }

  /**
   * Risk dimension this step covers (Business, Compliance, Legal, Security
   * and Privacy, Finance, or Programme).
   */
  @AuraEnabled
  public String dimension { get; set; }
  /**
   * Order this step appears in within its plan.
   */
  @AuraEnabled
  public Integer sequence { get; set; }
  /**
   * Current status of the step (Pending, Approved, Conditionally Approved,
   * Rejected, or More Information Required).
   */
  @AuraEnabled
  public String status { get; set; }

  /**
   * Id of the user this step is assigned to, if any.
   */
  @AuraEnabled
  public Id assignedToId { get; set; }
  /**
   * Name of the user this step is assigned to, if any.
   */
  @AuraEnabled
  public String assignedToName { get; set; }

  /**
   * Name of the user who last decided this step, if any.
   */
  @AuraEnabled
  public String decisionByName { get; set; }
  /**
   * Date/time this step was last decided, if any.
   */
  @AuraEnabled
  public Datetime decisionOn { get; set; }
  /**
   * Reason recorded for the step's last decision, if any.
   */
  @AuraEnabled
  public String decisionReason { get; set; }

  /**
   * Whether the running user may decide this step: unassigned steps may be
   * decided by any reviewer with the required permission; assigned steps
   * only by their assignee.
   */
  @AuraEnabled
  public Boolean canDecide { get; set; }
}
