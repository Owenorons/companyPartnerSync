/**
 * Evaluates whether a Deal_Revenue_Attribution__c is eligible for a
 * Partner_Incentive__c under a given Partner_Incentive_Policy__mdt (doc
 * Sprint 41 §41.34). evaluate() is the pure, bulk-safe core (mirrors
 * ImplementationHealthService.computeHealth()'s shape) - no SOQL, callers
 * supply the already-loaded inputs.
 */
public class PartnerIncentiveEligibilityService {
  public static final String ELIGIBLE = 'Eligible';
  public static final String INELIGIBLE = 'Ineligible';

  /**
   * Pure eligibility evaluation over pre-loaded inputs.
   *
   * @param attributionConfirmed True if the attribution row is Calculated/Confirmed/Overridden (not Draft/Reversed).
   * @param attributionTypeMatches True if the attribution's type satisfies the policy's Required_Attribution_Type__c (or none is required).
   * @param attributionPercentageMeetsMinimum True if the attribution percentage meets Minimum_Attribution_Percentage__c.
   * @param protectionRequired The policy's Require_Protection__c flag.
   * @param hasActiveProtection Whether the deal currently has an active protection grant.
   * @param implementationCompletionRequired The policy's Require_Implementation_Completion__c flag.
   * @param implementationCompleted Whether the deal's implementation (if any) is Completed.
   * @param eligibleBaseAmount The attributed amount this incentive would be based on.
   * @param minimumRevenue The policy's Minimum_Revenue__c threshold, if any.
   * @return ELIGIBLE or INELIGIBLE.
   */
  public static String evaluate(
    Boolean attributionConfirmed,
    Boolean attributionTypeMatches,
    Boolean attributionPercentageMeetsMinimum,
    Boolean protectionRequired,
    Boolean hasActiveProtection,
    Boolean implementationCompletionRequired,
    Boolean implementationCompleted,
    Decimal eligibleBaseAmount,
    Decimal minimumRevenue
  ) {
    if (attributionConfirmed != true) {
      return INELIGIBLE;
    }
    if (attributionTypeMatches != true) {
      return INELIGIBLE;
    }
    if (attributionPercentageMeetsMinimum != true) {
      return INELIGIBLE;
    }
    if (protectionRequired == true && hasActiveProtection != true) {
      return INELIGIBLE;
    }
    if (
      implementationCompletionRequired == true &&
      implementationCompleted != true
    ) {
      return INELIGIBLE;
    }
    if (
      minimumRevenue != null &&
      (eligibleBaseAmount == null ||
      eligibleBaseAmount < minimumRevenue)
    ) {
      return INELIGIBLE;
    }
    return ELIGIBLE;
  }
}
