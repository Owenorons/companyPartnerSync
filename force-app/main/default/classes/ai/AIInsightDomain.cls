public with sharing class AIInsightDomain {
  public static AIInsightDTO toDTO(AI_Insight__c record) {
    AIInsightDTO dto = new AIInsightDTO();

    dto.insightId = record.Id;
    dto.insightType = record.Feature_Name__c;
    dto.provider = record.Provider__c;
    dto.confidence = record.Confidence__c;
    dto.recommendation = record.Recommendation__c;
    dto.summary = record.Insight_Text__c;
    dto.reason = record.Insight_Text__c;
    dto.status = record.Status__c;
    dto.generatedOn = record.CreatedDate;

    return dto;
  }
}
