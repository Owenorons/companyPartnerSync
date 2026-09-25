/**
 * Full detail shape for a single deal review step on the "my pending deal
 * review steps" workspace, including the deciding user's permission flag.
 */
public with sharing class DealReviewStepDetailDTO {
  /**
   * Id of the deal review step record.
   */
  @AuraEnabled
  public Id reviewId { get; set; }
  /**
   * Id of the deal this review step belongs to.
   */
  @AuraEnabled
  public Id dealId { get; set; }
  /**
   * Denormalized display label for the deal.
   */
  @AuraEnabled
  public String dealLabel { get; set; }

  /**
   * Developer name of the routing rule this step was generated from.
   */
  @AuraEnabled
  public String reviewKey { get; set; }
  /**
   * Review type (e.g. Channel, Commercial).
   */
  @AuraEnabled
  public String reviewType { get; set; }
  /**
   * Sequence position of this step within its plan.
   */
  @AuraEnabled
  public Integer sequence { get; set; }
  /**
   * Current status of the step (e.g. Ready, In Progress, Blocked).
   */
  @AuraEnabled
  public String status { get; set; }
  /**
   * Whether this step blocks final deal approval until resolved.
   */
  @AuraEnabled
  public Boolean blocking { get; set; }
  /**
   * Review key this step is blocked on, if any.
   */
  @AuraEnabled
  public String dependsOnKey { get; set; }

  /**
   * When this step is due, per its routing rule's SLA.
   */
  @AuraEnabled
  public Datetime dueOn { get; set; }
  /**
   * Date/time this step was generated.
   */
  @AuraEnabled
  public Datetime generatedOn { get; set; }

  /**
   * Outcome recorded on this step, if completed.
   */
  @AuraEnabled
  public String outcome { get; set; }
  /**
   * Reason given for a recusal, if any.
   */
  @AuraEnabled
  public String recusalReason { get; set; }
  /**
   * Reason given for a waiver, if any.
   */
  @AuraEnabled
  public String waiverReason { get; set; }
  /**
   * Date/time work on this step started, if any.
   */
  @AuraEnabled
  public Datetime startedOn { get; set; }
  /**
   * Date/time this step was completed, if any.
   */
  @AuraEnabled
  public Datetime completedOn { get; set; }
  /**
   * Date/time this step was escalated, if any.
   */
  @AuraEnabled
  public Datetime escalatedOn { get; set; }

  /**
   * Optimistic-concurrency version to round-trip back on a decision request.
   */
  @AuraEnabled
  public Integer expectedVersion { get; set; }

  /**
   * Whether the running user currently has authority to work this step. A
   * UI hide/disable hint only - DealReviewCommandService.execute()
   * re-checks authority when an action is actually submitted.
   */
  @AuraEnabled
  public Boolean canDecide { get; set; }

  /**
   * Whether the running user currently has general review-management
   * authority to reassign this step - separate from canDecide since
   * Reassign is gated differently (see DealReviewCommandService.apply()),
   * specifically so a Routing Failed step (which canDecide always excludes)
   * still has a recovery path.
   */
  @AuraEnabled
  public Boolean canReassign { get; set; }
}
