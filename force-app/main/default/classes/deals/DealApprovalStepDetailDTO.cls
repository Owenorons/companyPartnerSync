/**
 * Full detail shape for a single approval step on the "my pending approval
 * steps" workspace, including the deciding user's permission flag. Compare
 * to DealReviewDetailDTO, the equivalent detail shape for the internal deal
 * review screen.
 */
public with sharing class DealApprovalStepDetailDTO {
  /**
   * Id of the approval step record.
   */
  @AuraEnabled
  public Id approvalId { get; set; }
  /**
   * Id of the deal registration the step belongs to.
   */
  @AuraEnabled
  public Id dealId { get; set; }
  /**
   * Display name/number of the deal registration record.
   */
  @AuraEnabled
  public String dealNumber { get; set; }
  /**
   * Name of the customer account associated with the deal.
   */
  @AuraEnabled
  public String customerName { get; set; }
  /**
   * Name of the partner account that submitted the deal.
   */
  @AuraEnabled
  public String partnerName { get; set; }

  /**
   * Developer name of the step rule this step was generated from.
   */
  @AuraEnabled
  public String stepKey { get; set; }
  /**
   * Sequence position of this step within its plan.
   */
  @AuraEnabled
  public Integer sequence { get; set; }
  /**
   * Current status of the step (e.g. Pending, Completed, Routing Failed).
   */
  @AuraEnabled
  public String status { get; set; }

  /**
   * Estimated revenue value of the deal the step is gating.
   */
  @AuraEnabled
  public Decimal estimatedRevenue { get; set; }
  /**
   * Maximum deal amount this step's decision authority covers.
   */
  @AuraEnabled
  public Decimal authorityLimit { get; set; }
  /**
   * Date/time the deal registration was submitted for review.
   */
  @AuraEnabled
  public Datetime submittedOn { get; set; }

  /**
   * Decision already recorded on this step, if any.
   */
  @AuraEnabled
  public String decision { get; set; }
  /**
   * Reason given for the recorded decision, if any.
   */
  @AuraEnabled
  public String decisionReason { get; set; }
  /**
   * Date/time the decision was recorded, if any.
   */
  @AuraEnabled
  public Datetime decisionOn { get; set; }

  /**
   * Optimistic-concurrency version to round-trip back on a decision request.
   */
  @AuraEnabled
  public Integer expectedVersion { get; set; }

  /**
   * Whether the running user currently has authority to decide this step.
   * A UI hide/disable hint only - DealApprovalCommandService.complete()
   * re-checks authority when a decision is actually submitted.
   */
  @AuraEnabled
  public Boolean canDecide { get; set; }
}
