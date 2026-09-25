/**
 * Row shape for the "my pending approval steps" queue (see
 * ApprovalSelector.selectMyPendingSteps). Object-agnostic: works for any
 * approval-routed object (Deal, MDF, ...), which is why it carries a
 * denormalized targetLabel rather than object-specific display fields.
 */
public with sharing class ApprovalStepListDTO {
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
}
