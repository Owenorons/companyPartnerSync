/**
 * Maps AI_Insight__c records to AIInsightDTO for both the internal admin
 * UI and the partner-facing insight/next-best-action surfaces.
 */
public with sharing class AIInsightDomain {
  /**
   * Converts an AI_Insight__c record to its DTO representation.
   *
   * @param record The AI_Insight__c record to convert.
   * @return The corresponding AIInsightDTO.
   */
  public static AIInsightDTO toDTO(AI_Insight__c record) {
    AIInsightDTO dto = new AIInsightDTO();

    dto.insightId = record.Id;
    dto.partnerAccountId = record.Partner_Account__c;
    dto.partnerName = record.Partner_Account__r?.Name;
    dto.insightType = record.Feature_Name__c;
    dto.provider = record.Provider__c;
    dto.confidence = record.Confidence__c;
    dto.recommendation = record.Recommendation__c;
    // summary and reason intentionally read the same field: consumers
    // (e.g. NextBestActionService) pick whichever label fits their UI -
    // there is no separate rationale field on AI_Insight__c today.
    dto.summary = record.Insight_Text__c;
    dto.reason = record.Insight_Text__c;
    dto.status = record.Status__c;
    dto.generatedOn = record.CreatedDate;

    return dto;
  }

  /**
   * Converts an AI_Feature_Config__mdt into its type-picker DTO. Shared
   * by both AIInsightController and PartnerAIController so the two
   * insight-type endpoints stay in sync.
   *
   * @param feature The AI_Feature_Config__mdt to convert.
   * @return The corresponding AIInsightTypeDTO.
   */
  public static AIInsightTypeDTO toTypeDTO(AI_Feature_Config__mdt feature) {
    AIInsightTypeDTO dto = new AIInsightTypeDTO();
    dto.developerName = feature.DeveloperName;
    dto.label = feature.Feature_Name__c;
    return dto;
  }

  /**
   * Converts an AI_Insight_Request__c into its list-row DTO.
   *
   * @param record The AI_Insight_Request__c to convert.
   * @param insightTypeLabel Display label for the request's insight type.
   * @return The corresponding AIInsightRequestListDTO.
   */
  public static AIInsightRequestListDTO toRequestDTO(
    AI_Insight_Request__c record,
    String insightTypeLabel
  ) {
    AIInsightRequestListDTO dto = new AIInsightRequestListDTO();
    dto.requestId = record.Id;
    dto.partnerAccountId = record.Partner_Account__c;
    dto.partnerName = record.Partner_Account__r?.Name;
    dto.insightType = record.Insight_Type__c;
    dto.insightTypeLabel = insightTypeLabel;
    dto.notes = record.Notes__c;
    dto.status = record.Status__c;
    dto.requestedOn = record.Requested_On__c;
    return dto;
  }
}
