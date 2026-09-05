public with sharing class OnboardingWorkItemDTO {
  @AuraEnabled
  public Id recordId { get; set; }
  @AuraEnabled
  public Id onboardingId { get; set; }
  @AuraEnabled
  public String queueType { get; set; }
  @AuraEnabled
  public String title { get; set; }
  @AuraEnabled
  public String status { get; set; }
  @AuraEnabled
  public String priority { get; set; }
  @AuraEnabled
  public Datetime dueOn { get; set; }
}
