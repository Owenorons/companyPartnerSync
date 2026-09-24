/**
 * Row shape for the "my pending approval steps" queue (see
 * DealApprovalSelector.selectMyPendingSteps). Compare to DealReviewListDTO,
 * the equivalent row shape for the internal deal review queue.
 */
public with sharing class DealApprovalStepListDTO {
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
}
