/**
 * Row shape for the "my pending deal review steps" queue (see
 * DealReviewStepSelector.selectMyPendingSteps).
 */
public with sharing class DealReviewStepListDTO {
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
   * Whether this step is stuck with nobody routed to it and needs
   * reassignment (Status__c = 'Routing Failed').
   */
  @AuraEnabled
  public Boolean needsReassignment { get; set; }
}
