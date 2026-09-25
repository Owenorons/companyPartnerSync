/**
 * Computes an MDF request's eligible funding ceiling from the tenant's
 * industry-scoped MDF_Calculation_Rule__mdt configuration. Every
 * Calculation_Model__c collapses to the same formula - eligible =
 * requestedAmount x (Rate__c ?? 1), clamped to Cap__c if set -
 * Calculation_Model__c is an admin-facing label only, not a branch point
 * here. Returns null when no active rule matches, so a tenant with no
 * configured rules sees no change in behaviour (gated only by the existing
 * account-level annual budget check in MDFApprovalService).
 */
public with sharing class MDFCalculationEngine {
  @TestVisible
  private static MDF_Calculation_Rule__mdt testRule;
  @TestVisible
  private static Boolean testForceNoMatch = false;

  /**
   * Computes the eligible funding ceiling for a requested amount and campaign type, using the
   * best-matching active rule for the tenant's configured industry.
   *
   * @param requestedAmount The amount requested for MDF funding.
   * @param campaignType The request's Campaign_Type__c value.
   * @return The eligible ceiling, or null if no active rule matches.
   */
  public static Decimal computeEligibleAmount(
    Decimal requestedAmount,
    String campaignType
  ) {
    if (requestedAmount == null || requestedAmount <= 0) {
      return null;
    }

    MDF_Calculation_Rule__mdt rule = resolveRule(requestedAmount, campaignType);
    if (rule == null) {
      return null;
    }

    Decimal rate = rule.Rate__c == null ? 1 : rule.Rate__c;
    Decimal eligible = requestedAmount * rate;

    if (rule.Cap__c != null && eligible > rule.Cap__c) {
      eligible = rule.Cap__c;
    }

    return eligible;
  }

  private static MDF_Calculation_Rule__mdt resolveRule(
    Decimal requestedAmount,
    String campaignType
  ) {
    if (Test.isRunningTest() && testForceNoMatch) {
      return null;
    }
    if (Test.isRunningTest() && testRule != null) {
      return testRule;
    }

    String industry = TenantConfigService.getIndustry();

    List<MDF_Calculation_Rule__mdt> rules = [
      SELECT Rate__c, Cap__c
      FROM MDF_Calculation_Rule__mdt
      WHERE
        Active__c = TRUE
        AND (Industry__r.DeveloperName = :industry
        OR Industry__c = NULL)
        AND (Campaign_Type__c = :campaignType
        OR Campaign_Type__c = NULL)
        AND (Minimum_Amount__c = NULL
        OR Minimum_Amount__c <= :requestedAmount)
        AND (Maximum_Amount__c = NULL
        OR Maximum_Amount__c >= :requestedAmount)
      WITH SYSTEM_MODE
      ORDER BY Sequence__c, DeveloperName
      LIMIT 1
    ];

    return rules.isEmpty() ? null : rules[0];
  }
}
