/**
 * DTO carrying an insight-generation request (target record, insight
 * type, and arbitrary context data) from the LWC layer into
 * AIInsightGeneratorService.
 */
public with sharing class AIInsightRequestDTO {
  /**
   * Id of the partner Account the insight is generated for.
   */
  @AuraEnabled
  public Id partnerAccountId { get; set; }

  /**
   * API name of the SObject the insight relates to, if any.
   */
  @AuraEnabled
  public String relatedObject { get; set; }

  /**
   * Id of the specific related record the insight relates to, if any.
   */
  @AuraEnabled
  public Id relatedRecordId { get; set; }

  /**
   * The AI feature/insight type to generate (matches AI_Feature_Config__mdt).
   */
  @AuraEnabled
  public String insightType { get; set; }

  /**
   * Arbitrary key/value context data passed into the generation prompt.
   */
  @AuraEnabled
  public Map<String, Object> contextData { get; set; }
}
