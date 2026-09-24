/**
 * DTO carrying a generated AI_Insight__c record to the LWC layer, used by
 * both the internal admin insight UI and the partner-facing insight and
 * next-best-action components.
 */
public with sharing class AIInsightDTO {
  /**
   * Id of the underlying AI_Insight__c record.
   */
  @AuraEnabled
  public Id insightId { get; set; }

  /**
   * Id of the partner Account this insight is about.
   */
  @AuraEnabled
  public Id partnerAccountId { get; set; }

  /**
   * Name of the partner Account this insight is about. Only populated by
   * queries that traverse the relationship (e.g. the internal governance
   * queue, which reviews insights across many partners); the partner-
   * facing surfaces don't need it since they're already scoped to one
   * partner's own insights.
   */
  @AuraEnabled
  public String partnerName { get; set; }

  /**
   * The AI feature/insight type that produced this record (Feature_Name__c).
   */
  @AuraEnabled
  public String insightType { get; set; }

  /**
   * Name of the AI provider that generated this insight.
   */
  @AuraEnabled
  public String provider { get; set; }

  /**
   * Model-reported confidence score for this insight.
   */
  @AuraEnabled
  public Decimal confidence { get; set; }

  /**
   * The recommended action associated with this insight.
   */
  @AuraEnabled
  public String recommendation { get; set; }

  /**
   * Human-readable summary of the insight (mirrors Insight_Text__c).
   */
  @AuraEnabled
  public String summary { get; set; }

  /**
   * Rationale for the insight (mirrors Insight_Text__c; same source as summary).
   */
  @AuraEnabled
  public String reason { get; set; }

  /**
   * Review status of the insight (e.g. Draft, Reviewed, Accepted, Dismissed).
   */
  @AuraEnabled
  public String status { get; set; }

  /**
   * Date/time the underlying insight record was created.
   */
  @AuraEnabled
  public Datetime generatedOn { get; set; }
}
