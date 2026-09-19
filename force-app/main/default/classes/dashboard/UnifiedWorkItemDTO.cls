/**
 * DTO representing a single item in the unified cross-domain work queue
 * (combining onboarding, compliance and other work types into one list).
 */
public with sharing class UnifiedWorkItemDTO {
  /**
   * Id of the underlying record for this work item.
   */
  @AuraEnabled
  public Id recordId { get; set; }
  /**
   * Id of the parent record this work item belongs to.
   */
  @AuraEnabled
  public Id parentId { get; set; }
  /**
   * Domain the work item belongs to (e.g. onboarding, compliance).
   */
  @AuraEnabled
  public String domain { get; set; }
  /**
   * Type of work represented by this item.
   */
  @AuraEnabled
  public String workType { get; set; }
  /**
   * Display title for the work item.
   */
  @AuraEnabled
  public String title { get; set; }
  /**
   * Current status of the work item.
   */
  @AuraEnabled
  public String status { get; set; }
  /**
   * Priority of the work item.
   */
  @AuraEnabled
  public String priority { get; set; }
  /**
   * Date/time the work item is due.
   */
  @AuraEnabled
  public Datetime dueOn { get; set; }
}
