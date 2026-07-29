/*
 * Maps AI_Insight__c records to AIInsightDTO for both the internal admin
 * UI and the partner-facing insight/next-best-action surfaces.
 */
public with sharing class AIInsightDomain {
  public static AIInsightDTO toDTO(AI_Insight__c record) {
    AIInsightDTO dto = new AIInsightDTO();

    dto.insightId = record.Id;
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
}
