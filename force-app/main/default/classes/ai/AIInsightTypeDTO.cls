/**
 * Row shape for the insight-type picker on the generate-insight forms
 * (governance console and, if enabled later, partner self-service).
 */
public with sharing class AIInsightTypeDTO {
  /**
   * DeveloperName of the AI_Feature_Config__mdt, used as
   * AIInsightRequestDTO.insightType.
   */
  @AuraEnabled
  public String developerName { get; set; }

  /**
   * Display label for the feature type.
   */
  @AuraEnabled
  public String label { get; set; }
}
