/**
 * Full detail shape for a single approval step on the "my pending approval
 * steps" workspace, including the deciding user's permission flag.
 * Object-agnostic, same as ApprovalStepListDTO.
 */
public with sharing class ApprovalStepDetailDTO {
  /**
   * Id of the approval step record.
   */
  @AuraEnabled
  public Id approvalId { get; set; }
  /**
   * API name of the target object this step approves.
   */
  @AuraEnabled
  public String objectName { get; set; }
  /**
   * Id of the target record this step approves.
   */
  @AuraEnabled
  public Id targetRecordId { get; set; }
  /**
   * Denormalized display label for the target record.
   */
  @AuraEnabled
  public String targetLabel { get; set; }

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
   * Amount the target record was evaluated against at generation time.
   */
  @AuraEnabled
  public Decimal targetAmount { get; set; }
  /**
   * Maximum amount this step's decision authority covers.
   */
  @AuraEnabled
  public Decimal authorityLimit { get; set; }
  /**
   * Date/time this step was generated.
   */
  @AuraEnabled
  public Datetime generatedOn { get; set; }

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
   * A UI hide/disable hint only - ApprovalCommandService.complete()
   * re-checks authority when a decision is actually submitted.
   */
  @AuraEnabled
  public Boolean canDecide { get; set; }
}
