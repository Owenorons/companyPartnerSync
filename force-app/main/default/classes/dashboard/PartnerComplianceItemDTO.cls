/** Portfolio-level evidence issue shown to authorised internal operators. */
public with sharing class PartnerComplianceItemDTO {
  @AuraEnabled
  public Id recordId { get; set; }
  @AuraEnabled
  public Id onboardingId { get; set; }
  @AuraEnabled
  public String category { get; set; }
  @AuraEnabled
  public String documentType { get; set; }
  @AuraEnabled
  public String status { get; set; }
  @AuraEnabled
  public String severity { get; set; }
  @AuraEnabled
  public Date dueOn { get; set; }
  @AuraEnabled
  public String message { get; set; }
}
