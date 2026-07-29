/*
 * DTO carrying a generated AI_Insight__c record to the LWC layer, used by
 * both the internal admin insight UI and the partner-facing insight and
 * next-best-action components.
 */
public with sharing class AIInsightDTO {
  @AuraEnabled
  public Id insightId;

  @AuraEnabled
  public String insightType;

  @AuraEnabled
  public String provider;

  @AuraEnabled
  public Decimal confidence;

  @AuraEnabled
  public String recommendation;

  @AuraEnabled
  public String summary;

  @AuraEnabled
  public String reason;

  @AuraEnabled
  public String status;

  @AuraEnabled
  public Datetime generatedOn;
}
