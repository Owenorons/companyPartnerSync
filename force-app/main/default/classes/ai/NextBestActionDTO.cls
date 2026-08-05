/*
 * DTO carrying a single recommended action, derived from an
 * AI_Insight__c, to the partner portal's Next Best Action component.
 */
public with sharing class NextBestActionDTO {
  @AuraEnabled
  public Id actionId { get; set; }

  @AuraEnabled
  public String title { get; set; }

  @AuraEnabled
  public String recommendation { get; set; }

  @AuraEnabled
  public String reason { get; set; }

  @AuraEnabled
  public String sourceSignal { get; set; }

  @AuraEnabled
  public Decimal confidence { get; set; }

  @AuraEnabled
  public String priority { get; set; }
}
