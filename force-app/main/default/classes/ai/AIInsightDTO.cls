/*
 * DTO carrying a generated AI_Insight__c record to the LWC layer, used by
 * both the internal admin insight UI and the partner-facing insight and
 * next-best-action components.
 */
public with sharing class AIInsightDTO {
  @AuraEnabled
  public Id insightId { get; set; }

  @AuraEnabled
  public String insightType { get; set; }

  @AuraEnabled
  public String provider { get; set; }

  @AuraEnabled
  public Decimal confidence { get; set; }

  @AuraEnabled
  public String recommendation { get; set; }

  @AuraEnabled
  public String summary { get; set; }

  @AuraEnabled
  public String reason { get; set; }

  @AuraEnabled
  public String status { get; set; }

  @AuraEnabled
  public Datetime generatedOn { get; set; }
}
