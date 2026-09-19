/**
 * DTO representing a single onboarding-related work item shown in the
 * internal review queue.
 */
public with sharing class OnboardingWorkItemDTO {
  /**
   * Id of the underlying record for this work item.
   */
  @AuraEnabled
  public Id recordId { get; set; }
  /**
   * Id of the onboarding record this work item belongs to.
   */
  @AuraEnabled
  public Id onboardingId { get; set; }
  /**
   * Queue/category this work item belongs to.
   */
  @AuraEnabled
  public String queueType { get; set; }
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
