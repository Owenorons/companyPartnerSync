/*
 * DTO carrying a single recommended action, derived from an
 * AI_Insight__c, to the partner portal's Next Best Action component.
 */
public with sharing class NextBestActionDTO {
  @AuraEnabled
  public Id actionId;

  @AuraEnabled
  public String title;

  @AuraEnabled
  public String recommendation;

  @AuraEnabled
  public String reason;

  @AuraEnabled
  public String sourceSignal;

  @AuraEnabled
  public Decimal confidence;

  @AuraEnabled
  public String priority;
}
