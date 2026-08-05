public with sharing class PartnerApplicationMatchDTO {
  @AuraEnabled
  public Id recordId { get; set; }
  @AuraEnabled
  public String recordType { get; set; }
  @AuraEnabled
  public String name { get; set; }
  @AuraEnabled
  public String emailOrWebsite { get; set; }
  @AuraEnabled
  public String matchReason { get; set; }
}
