/*
 * DTO carrying an insight-generation request (target record, insight
 * type, and arbitrary context data) from the LWC layer into
 * AIInsightGeneratorService.
 */
public with sharing class AIInsightRequestDTO {
  @AuraEnabled
  public Id partnerAccountId;

  @AuraEnabled
  public String relatedObject;

  @AuraEnabled
  public Id relatedRecordId;

  @AuraEnabled
  public String insightType;

  @AuraEnabled
  public Map<String, Object> contextData;
}
