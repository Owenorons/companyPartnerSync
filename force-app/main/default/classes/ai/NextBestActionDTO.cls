/**
 * DTO carrying a single recommended action, derived from an
 * AI_Insight__c, to the partner portal's Next Best Action component.
 */
public with sharing class NextBestActionDTO {
  /**
   * Id of the source AI_Insight__c record.
   */
  @AuraEnabled
  public Id actionId { get; set; }

  /**
   * Display title for the recommended action.
   */
  @AuraEnabled
  public String title { get; set; }

  /**
   * The recommended action text.
   */
  @AuraEnabled
  public String recommendation { get; set; }

  /**
   * Rationale for the recommendation.
   */
  @AuraEnabled
  public String reason { get; set; }

  /**
   * Name of the AI feature/signal the recommendation was derived from.
   */
  @AuraEnabled
  public String sourceSignal { get; set; }

  /**
   * Model-reported confidence score backing the recommendation.
   */
  @AuraEnabled
  public Decimal confidence { get; set; }

  /**
   * Display priority bucket (High, Medium, Low) derived from confidence.
   */
  @AuraEnabled
  public String priority { get; set; }
}
