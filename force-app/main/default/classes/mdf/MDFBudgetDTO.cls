/**
 * DTO carrying a partner's MDF budget standing (annual/used/remaining)
 * to the LWC layer.
 */
public with sharing class MDFBudgetDTO {
  /**
   * The partner's total annual MDF budget.
   */
  @AuraEnabled
  public Decimal annualBudget { get; set; }
  /**
   * The amount of the annual MDF budget already used.
   */
  @AuraEnabled
  public Decimal usedBudget { get; set; }
  /**
   * The amount of the annual MDF budget still available (annual minus
   * used).
   */
  @AuraEnabled
  public Decimal remainingBudget { get; set; }
}
