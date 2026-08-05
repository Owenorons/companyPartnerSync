/*
 * DTO carrying an insight-generation request (target record, insight
 * type, and arbitrary context data) from the LWC layer into
 * AIInsightGeneratorService.
 */
public with sharing class AIInsightRequestDTO {
  @AuraEnabled
  public Id partnerAccountId { get; set; }

  @AuraEnabled
  public String relatedObject { get; set; }

  @AuraEnabled
  public Id relatedRecordId { get; set; }

  @AuraEnabled
  public String insightType { get; set; }

  @AuraEnabled
  public Map<String, Object> contextData { get; set; }
}
