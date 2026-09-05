public with sharing class UnifiedWorkItemDTO {
  @AuraEnabled
  public Id recordId { get; set; }
  @AuraEnabled
  public Id parentId { get; set; }
  @AuraEnabled
  public String domain { get; set; }
  @AuraEnabled
  public String workType { get; set; }
  @AuraEnabled
  public String title { get; set; }
  @AuraEnabled
  public String status { get; set; }
  @AuraEnabled
  public String priority { get; set; }
  @AuraEnabled
  public Datetime dueOn { get; set; }
}
