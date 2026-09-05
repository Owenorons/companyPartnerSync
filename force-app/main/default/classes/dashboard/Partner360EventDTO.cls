public with sharing class Partner360EventDTO {
  @AuraEnabled
  public Id recordId { get; set; }
  @AuraEnabled
  public String eventType { get; set; }
  @AuraEnabled
  public String stage { get; set; }
  @AuraEnabled
  public String summary { get; set; }
  @AuraEnabled
  public Datetime occurredOn { get; set; }
}
