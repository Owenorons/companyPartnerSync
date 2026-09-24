/**
 * Classifies a deal registration as Partner-Sourced or Co-Sell from the
 * active Deal_Attribution_Rule__mdt policy: the underlying Opportunity's
 * age relative to the registration's Submitted_On__c. A vendor-configurable
 * threshold, not hardcoded business logic — different programs draw this
 * line differently (some treat any pre-existing Opportunity as Co-Sell,
 * others allow a grace window).
 */
public with sharing class DealAttributionEngine {
  public static final String PARTNER_SOURCED = 'Partner-Sourced';
  public static final String CO_SELL = 'Co-Sell';

  @TestVisible
  private static Deal_Attribution_Rule__mdt testPolicy;

  /**
   * Classifies a deal registration's attribution type.
   *
   * @param opportunityCreatedOn CreatedDate of the deal's underlying Opportunity.
   * @param submittedOn Date/time the deal registration was submitted.
   * @return 'Partner-Sourced' or 'Co-Sell'.
   */
  public static String classify(
    Datetime opportunityCreatedOn,
    Datetime submittedOn
  ) {
    Deal_Attribution_Rule__mdt policy = activePolicy();
    if (policy == null) {
      return PARTNER_SOURCED;
    }
    if (opportunityCreatedOn == null || submittedOn == null) {
      return policy.Default_Attribution_Type__c;
    }

    Integer ageDays = opportunityCreatedOn.date()
      .daysBetween(submittedOn.date());
    Integer thresholdDays = policy.Opportunity_Age_Threshold_Days__c == null
      ? 0
      : Integer.valueOf(policy.Opportunity_Age_Threshold_Days__c);

    return ageDays > thresholdDays ? CO_SELL : PARTNER_SOURCED;
  }

  private static Deal_Attribution_Rule__mdt activePolicy() {
    if (Test.isRunningTest() && testPolicy != null) {
      return testPolicy;
    }

    List<Deal_Attribution_Rule__mdt> policies = [
      SELECT Opportunity_Age_Threshold_Days__c, Default_Attribution_Type__c
      FROM Deal_Attribution_Rule__mdt
      WHERE Active__c = TRUE
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    return policies.isEmpty() ? null : policies[0];
  }
}
