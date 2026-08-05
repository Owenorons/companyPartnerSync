/*
 * DTO carrying a partner's MDF budget standing (annual/used/remaining)
 * to the LWC layer.
 */
public with sharing class MDFBudgetDTO {
  @AuraEnabled
  public Decimal annualBudget { get; set; }
  @AuraEnabled
  public Decimal usedBudget { get; set; }
  @AuraEnabled
  public Decimal remainingBudget { get; set; }
}
