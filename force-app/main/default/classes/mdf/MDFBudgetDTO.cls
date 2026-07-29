/*
 * DTO carrying a partner's MDF budget standing (annual/used/remaining)
 * to the LWC layer.
 */
public with sharing class MDFBudgetDTO {
  @AuraEnabled
  public Decimal annualBudget;
  @AuraEnabled
  public Decimal usedBudget;
  @AuraEnabled
  public Decimal remainingBudget;
}
