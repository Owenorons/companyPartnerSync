public with sharing class MDFBudgetDTO {
  @AuraEnabled
  public Decimal annualBudget;
  @AuraEnabled
  public Decimal usedBudget;
  @AuraEnabled
  public Decimal remainingBudget;
}
