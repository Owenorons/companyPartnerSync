/**
 * Calculates Deal_Revenue_Attribution__c rows for a confirmed
 * Deal_Revenue__c from the deal's Deal_Participant_Contribution__c roster
 * (doc Sprint 41 §41.21/§41.22), using each contribution's own
 * Effective_From__c/Effective_To__c against the revenue's Revenue_Date__c
 * rather than today's participant status (§41.23 - a participant removed
 * after the revenue's effective date must still receive historical
 * attribution).
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class DealRevenueAttributionService {
  // Revenue_Attribution_Policy__mdt is real-record CMDT with only one
  // seeded row ("Default"), so tests can't seed alternate policy
  // combinations per case - same test-override shape as
  // DealLifecyclePermissionService.testOverrides.
  @TestVisible
  private static Revenue_Attribution_Policy__mdt testPolicyOverride;

  // Contribution_Type__c -> Attribution_Type__c. "Sales"/"Technical"/
  // "Commercial" contributions are influence on the deal, not the
  // originating source of it - mapped to Influenced.
  private static final Map<String, String> ATTRIBUTION_TYPE_BY_CONTRIBUTION_TYPE = new Map<String, String>{
    'Origination' => 'Sourced',
    'Sales' => 'Influenced',
    'Technical' => 'Influenced',
    'Commercial' => 'Influenced',
    'Implementation' => 'Implementation',
    'Referral' => 'Referral',
    'Renewal' => 'Renewal',
    'Other' => 'Other'
  };

  /**
   * Calculates and persists attribution rows for a revenue record.
   *
   * @param revenueId Id of the confirmed Deal_Revenue__c to attribute.
   * @return The inserted Deal_Revenue_Attribution__c rows.
   */
  public static List<Deal_Revenue_Attribution__c> calculateAttribution(
    Id revenueId
  ) {
    List<Deal_Revenue__c> revenues = [
      SELECT
        Id,
        Deal__c,
        Revenue_Type__c,
        Net_Amount__c,
        Gross_Amount__c,
        Revenue_Date__c
      FROM Deal_Revenue__c
      WHERE Id = :revenueId
      WITH SYSTEM_MODE
    ];
    if (revenues.isEmpty()) {
      throw new PartnerSyncHandledException('Revenue record not found.');
    }
    Deal_Revenue__c revenue = revenues[0];
    if (revenue.Deal__c == null) {
      throw new PartnerSyncHandledException(
        'Revenue must be matched to a deal before attribution can be calculated.'
      );
    }

    Revenue_Attribution_Policy__mdt policy = resolvePolicy(
      revenue.Revenue_Type__c
    );

    if (
      policy.Require_Protection__c == true &&
      !hasActiveProtection(revenue.Deal__c)
    ) {
      throw new PartnerSyncHandledException(
        'This deal has no active protection grant - attribution cannot be calculated.'
      );
    }

    Date asOf = revenue.Revenue_Date__c == null
      ? Date.today()
      : revenue.Revenue_Date__c;
    List<Deal_Participant_Contribution__c> contributions = selectContributionsAsOf(
      revenue.Deal__c,
      asOf
    );

    if (
      policy.Require_Active_Participant__c == true && contributions.isEmpty()
    ) {
      throw new PartnerSyncHandledException(
        'No approved participant contribution exists for this deal as of the revenue date - attribution cannot be calculated.'
      );
    }

    Decimal baseAmount = revenue.Net_Amount__c != null
      ? revenue.Net_Amount__c
      : revenue.Gross_Amount__c;

    Map<String, Decimal> percentageByAttributionType = new Map<String, Decimal>();
    List<Deal_Revenue_Attribution__c> rows = new List<Deal_Revenue_Attribution__c>();

    for (Deal_Participant_Contribution__c contribution : contributions) {
      String attributionType = ATTRIBUTION_TYPE_BY_CONTRIBUTION_TYPE.get(
        contribution.Contribution_Type__c
      );
      if (attributionType == null) {
        attributionType = 'Other';
      }
      Decimal percentage = contribution.Percentage__c == null
        ? 0
        : contribution.Percentage__c;

      Decimal runningTotal = percentageByAttributionType.containsKey(
          attributionType
        )
        ? percentageByAttributionType.get(attributionType)
        : 0;
      runningTotal += percentage;
      percentageByAttributionType.put(attributionType, runningTotal);
      if (
        policy.Maximum_Percentage__c != null &&
        runningTotal > policy.Maximum_Percentage__c
      ) {
        throw new PartnerSyncHandledException(
          'Attribution percentage for ' +
            attributionType +
            ' exceeds the maximum allowed by policy ' +
            policy.Policy_Key__c +
            '.'
        );
      }

      Deal_Revenue_Attribution__c row = new Deal_Revenue_Attribution__c(
        Revenue__c = revenue.Id,
        Deal__c = revenue.Deal__c,
        Deal_Participant__c = contribution.Deal_Participant__c,
        Partner_Account__c = contribution.Deal_Participant__r.Partner_Account__c,
        Attribution_Type__c = attributionType,
        Attribution_Percentage__c = percentage,
        Attributed_Amount__c = baseAmount == null
          ? null
          : (baseAmount * percentage / 100).setScale(2),
        Status__c = 'Calculated',
        Policy_Key__c = policy.Policy_Key__c,
        Policy_Version__c = policy.Policy_Version__c,
        Calculation_Method__c = 'Participant Contribution',
        Calculation_Snapshot__c = JSON.serialize(
          new Map<String, Object>{
            'revenueId' => revenue.Id,
            'baseAmount' => baseAmount,
            'contributionId' => contribution.Id,
            'contributionType' => contribution.Contribution_Type__c,
            'percentage' => percentage,
            'policyKey' => policy.Policy_Key__c,
            'policyVersion' => policy.Policy_Version__c
          }
        ),
        Effective_On__c = Datetime.newInstance(
          asOf,
          Time.newInstance(0, 0, 0, 0)
        ),
        Version_Number__c = 0
      );
      rows.add(row);
    }

    if (!rows.isEmpty()) {
      Database.insert(rows, AccessLevel.SYSTEM_MODE);

      PlatformEventPublisherService.publish(
        'RevenueAttributionCalculated',
        revenue.Deal__c,
        'Deal_Revenue__c',
        null,
        'Revenue attribution was calculated.',
        'Info'
      );
    }

    return rows;
  }

  private static List<Deal_Participant_Contribution__c> selectContributionsAsOf(
    Id dealId,
    Date asOf
  ) {
    return [
      SELECT
        Id,
        Deal_Participant__c,
        Deal_Participant__r.Partner_Account__c,
        Contribution_Type__c,
        Percentage__c,
        Effective_From__c,
        Effective_To__c
      FROM Deal_Participant_Contribution__c
      WHERE
        Deal_Participant__r.Deal__c = :dealId
        AND Approved__c = TRUE
        AND Effective_From__c <= :asOf
        AND (Effective_To__c = NULL
        OR Effective_To__c >= :asOf)
      WITH SYSTEM_MODE
    ];
  }

  private static Boolean hasActiveProtection(Id dealId) {
    return [
        SELECT COUNT()
        FROM Deal_Protection_Grant__c
        WHERE Deal__c = :dealId AND Status__c = 'Active' AND Current__c = TRUE
        WITH SYSTEM_MODE
      ] > 0;
  }

  private static Revenue_Attribution_Policy__mdt resolvePolicy(
    String revenueType
  ) {
    if (Test.isRunningTest() && testPolicyOverride != null) {
      return testPolicyOverride;
    }
    List<Revenue_Attribution_Policy__mdt> exactMatches = [
      SELECT
        Policy_Key__c,
        Policy_Version__c,
        Attribution_Type__c,
        Require_Protection__c,
        Require_Active_Participant__c,
        Require_Implementation_Completion__c,
        Maximum_Percentage__c,
        Allow_Override__c
      FROM Revenue_Attribution_Policy__mdt
      WHERE Active__c = TRUE AND Revenue_Type__c = :revenueType
      WITH SYSTEM_MODE
      ORDER BY Priority__c DESC NULLS LAST
      LIMIT 1
    ];
    if (!exactMatches.isEmpty()) {
      return exactMatches[0];
    }

    List<Revenue_Attribution_Policy__mdt> fallback = [
      SELECT
        Policy_Key__c,
        Policy_Version__c,
        Attribution_Type__c,
        Require_Protection__c,
        Require_Active_Participant__c,
        Require_Implementation_Completion__c,
        Maximum_Percentage__c,
        Allow_Override__c
      FROM Revenue_Attribution_Policy__mdt
      WHERE Active__c = TRUE AND Revenue_Type__c = NULL
      WITH SYSTEM_MODE
      ORDER BY Priority__c DESC NULLS LAST
      LIMIT 1
    ];
    if (fallback.isEmpty()) {
      throw new PartnerSyncHandledException(
        'No active Revenue Attribution Policy is configured.'
      );
    }
    return fallback[0];
  }
}
