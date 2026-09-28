/**
 * Executes Partner_Incentive__c commands: evaluate (eligibility, doc
 * §41.34), calculate (policy-driven, §41.30-41.33). Calculated_Amount__c/
 * Approved_Amount__c/Paid_Amount__c stay three genuinely separate fields
 * per §41.29 - calculate() only ever writes Calculated_Amount__c.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class IncentiveCommandService {
  // Partner_Incentive_Policy__mdt is real-record CMDT with only one
  // seeded row ("Default"), so tests can't seed alternate policy
  // combinations per case - same test-override shape as
  // DealRevenueAttributionService.testPolicyOverride.
  @TestVisible
  private static Partner_Incentive_Policy__mdt testPolicyOverride;

  // Only these three calculation types are implemented - Threshold/
  // Formula/External are recognised CMDT values that raise a clear error
  // rather than silently no-opping (see Partner_Incentive_Policy__mdt's
  // Calculation_Type__c field description).
  private static final Set<String> SUPPORTED_CALCULATION_TYPES = new Set<String>{
    'Percentage of Attributed Revenue',
    'Fixed Amount',
    'Tiered'
  };

  /**
   * Evaluates eligibility for a revenue attribution row and creates a
   * Partner_Incentive__c reflecting the outcome. Idempotent - a second
   * evaluate() for the same attribution returns the existing record.
   *
   * @param command revenueAttributionId (+ optional incentiveType, defaults to Commission).
   * @return The Eligible/Ineligible Partner_Incentive__c.
   */
  public static Partner_Incentive__c evaluate(IncentiveCommand command) {
    if (command.revenueAttributionId == null) {
      throw new PartnerSyncHandledException(
        'A revenue attribution is required to evaluate incentive eligibility.'
      );
    }

    Partner_Incentive__c existing = IncentiveSelector.selectForAttribution(
      command.revenueAttributionId
    );
    if (existing != null) {
      return existing;
    }

    List<Deal_Revenue_Attribution__c> attributions = [
      SELECT
        Id,
        Revenue__c,
        Deal__c,
        Partner_Account__c,
        Deal_Participant__c,
        Attribution_Type__c,
        Attribution_Percentage__c,
        Attributed_Amount__c,
        Status__c
      FROM Deal_Revenue_Attribution__c
      WHERE Id = :command.revenueAttributionId
      WITH SYSTEM_MODE
    ];
    if (attributions.isEmpty()) {
      throw new PartnerSyncHandledException('Revenue attribution not found.');
    }
    Deal_Revenue_Attribution__c attribution = attributions[0];

    Partner_Incentive_Policy__mdt policy = resolvePolicy(command.incentiveType);

    Boolean hasActiveProtection =
      [
        SELECT COUNT()
        FROM Deal_Protection_Grant__c
        WHERE
          Deal__c = :attribution.Deal__c
          AND Status__c = 'Active'
          AND Current__c = TRUE
        WITH SYSTEM_MODE
      ] > 0;
    Boolean implementationCompleted =
      [
        SELECT COUNT()
        FROM Deal_Implementation__c
        WHERE Deal__c = :attribution.Deal__c AND Status__c = 'Completed'
        WITH SYSTEM_MODE
      ] > 0;

    String eligibility = PartnerIncentiveEligibilityService.evaluate(
      attribution.Status__c == 'Calculated' ||
        attribution.Status__c == 'Confirmed' ||
        attribution.Status__c == 'Overridden',
      String.isBlank(policy.Required_Attribution_Type__c) ||
      policy.Required_Attribution_Type__c == attribution.Attribution_Type__c,
      policy.Minimum_Attribution_Percentage__c == null ||
      (attribution.Attribution_Percentage__c != null &&
      attribution.Attribution_Percentage__c >=
      policy.Minimum_Attribution_Percentage__c),
      policy.Require_Protection__c == true,
      hasActiveProtection,
      policy.Require_Implementation_Completion__c == true,
      implementationCompleted,
      attribution.Attributed_Amount__c,
      policy.Minimum_Revenue__c
    );

    Partner_Incentive__c incentive = new Partner_Incentive__c(
      Deal__c = attribution.Deal__c,
      Revenue__c = attribution.Revenue__c,
      Revenue_Attribution__c = attribution.Id,
      Partner_Account__c = attribution.Partner_Account__c,
      Deal_Participant__c = attribution.Deal_Participant__c,
      Incentive_Type__c = String.isBlank(command.incentiveType)
        ? 'Commission'
        : command.incentiveType,
      Status__c = eligibility,
      Eligible_Base_Amount__c = attribution.Attributed_Amount__c,
      Eligibility_Date__c = Date.today(),
      Version_Number__c = 0
    );
    Database.insert(incentive, AccessLevel.SYSTEM_MODE);

    PlatformEventPublisherService.publish(
      eligibility == PartnerIncentiveEligibilityService.ELIGIBLE
        ? 'PartnerIncentiveEligible'
        : 'PartnerIncentiveIneligible',
      incentive.Deal__c,
      'Deal_Registration__c',
      incentive.Partner_Account__c,
      'Partner incentive eligibility was evaluated.',
      'Info'
    );

    return incentive;
  }

  /**
   * Calculates Calculated_Amount__c for an Eligible incentive using its
   * policy's Calculation_Type__c.
   *
   * @param command incentiveId + expectedVersion.
   */
  public static void calculate(IncentiveCommand command) {
    Partner_Incentive__c incentive = selectAndCheckVersion(command);
    if (incentive.Status__c != 'Eligible') {
      throw new PartnerSyncHandledException(
        'Only an eligible incentive can be calculated.'
      );
    }

    Partner_Incentive_Policy__mdt policy = resolvePolicy(
      incentive.Incentive_Type__c
    );
    if (!SUPPORTED_CALCULATION_TYPES.contains(policy.Calculation_Type__c)) {
      throw new PartnerSyncHandledException(
        'Incentive calculation type is not yet supported: ' +
        policy.Calculation_Type__c
      );
    }

    Decimal baseAmount = incentive.Eligible_Base_Amount__c == null
      ? 0
      : incentive.Eligible_Base_Amount__c;
    Decimal calculatedAmount;
    if (policy.Calculation_Type__c == 'Percentage of Attributed Revenue') {
      Decimal rate = policy.Rate__c == null ? 0 : policy.Rate__c;
      calculatedAmount = (baseAmount * rate / 100).setScale(2);
      incentive.Rate__c = rate;
    } else if (policy.Calculation_Type__c == 'Fixed Amount') {
      calculatedAmount = policy.Fixed_Amount__c == null
        ? 0
        : policy.Fixed_Amount__c;
    } else {
      calculatedAmount = calculateTiered(policy.Policy_Key__c, baseAmount);
    }

    if (
      policy.Maximum_Incentive__c != null &&
      calculatedAmount > policy.Maximum_Incentive__c
    ) {
      calculatedAmount = policy.Maximum_Incentive__c;
    }

    incentive.Calculated_Amount__c = calculatedAmount;
    incentive.Calculation_Snapshot__c = JSON.serialize(
      new Map<String, Object>{
        'incentiveId' => incentive.Id,
        'baseAmount' => baseAmount,
        'calculationType' => policy.Calculation_Type__c,
        'policyKey' => policy.Policy_Key__c,
        'policyVersion' => policy.Policy_Version__c,
        'calculatedAmount' => calculatedAmount
      }
    );
    incentive.Status__c = policy.Claim_Required__c == true
      ? 'Claim Required'
      : (policy.Approval_Required__c == true ? 'Under Review' : 'Approved');
    incentive.Version_Number__c = versionAfter(incentive);
    Database.update(incentive, AccessLevel.SYSTEM_MODE);

    publish(
      'PartnerIncentiveCalculated',
      incentive,
      'Partner incentive was calculated.'
    );
  }

  /**
   * Cancels an incentive that's no longer applicable (e.g. following a
   * revenue reversal, doc §41.42).
   *
   * @param command incentiveId + expectedVersion.
   */
  public static void cancel(IncentiveCommand command) {
    Partner_Incentive__c incentive = selectAndCheckVersion(command);
    if (incentive.Status__c == 'Paid') {
      throw new PartnerSyncHandledException(
        'A paid incentive cannot be cancelled directly - reverse the payment first.'
      );
    }
    incentive.Status__c = incentive.Calculated_Amount__c == null
      ? 'Cancelled'
      : 'Reversed';
    incentive.Version_Number__c = versionAfter(incentive);
    Database.update(incentive, AccessLevel.SYSTEM_MODE);
  }

  private static Decimal calculateTiered(String policyKey, Decimal baseAmount) {
    List<Partner_Incentive_Tier__mdt> tiers = new List<Partner_Incentive_Tier__mdt>();
    for (
      Partner_Incentive_Tier__mdt tier : Partner_Incentive_Tier__mdt.getAll()
        .values()
    ) {
      if (tier.Policy_Key__c == policyKey) {
        tiers.add(tier);
      }
    }
    sortBySequence(tiers);

    Decimal remaining = baseAmount;
    Decimal total = 0;
    for (Partner_Incentive_Tier__mdt tier : tiers) {
      if (remaining <= 0) {
        break;
      }
      Decimal tierMin = tier.Minimum_Amount__c == null
        ? 0
        : tier.Minimum_Amount__c;
      Decimal tierMax = tier.Maximum_Amount__c;
      Decimal tierCapacity = tierMax == null ? remaining : (tierMax - tierMin);
      Decimal amountInTier = tierCapacity < remaining
        ? tierCapacity
        : remaining;
      if (amountInTier <= 0) {
        continue;
      }
      Decimal rate = tier.Rate__c == null ? 0 : tier.Rate__c;
      total += (amountInTier * rate / 100);
      remaining -= amountInTier;
    }
    return total.setScale(2);
  }

  // Partner_Incentive_Tier__mdt has no natural sort order List.sort() can
  // use (sObject lists don't sort meaningfully without a Comparator), and
  // the tiered calculation must process tiers in ascending Sequence__c
  // order to allocate marginal amounts correctly - a simple selection
  // sort is fine given the handful of tiers a single policy ever has.
  private static void sortBySequence(List<Partner_Incentive_Tier__mdt> tiers) {
    for (Integer i = 0; i < tiers.size() - 1; i++) {
      Integer smallest = i;
      for (Integer j = i + 1; j < tiers.size(); j++) {
        Decimal jSequence = tiers[j].Sequence__c == null
          ? 0
          : tiers[j].Sequence__c;
        Decimal smallestSequence = tiers[smallest].Sequence__c == null
          ? 0
          : tiers[smallest].Sequence__c;
        if (jSequence < smallestSequence) {
          smallest = j;
        }
      }
      if (smallest != i) {
        Partner_Incentive_Tier__mdt swap = tiers[i];
        tiers[i] = tiers[smallest];
        tiers[smallest] = swap;
      }
    }
  }

  private static Partner_Incentive_Policy__mdt resolvePolicy(
    String incentiveType
  ) {
    if (Test.isRunningTest() && testPolicyOverride != null) {
      return testPolicyOverride;
    }
    List<Partner_Incentive_Policy__mdt> exactMatches = [
      SELECT
        Policy_Key__c,
        Policy_Version__c,
        Required_Attribution_Type__c,
        Minimum_Attribution_Percentage__c,
        Require_Protection__c,
        Require_Implementation_Completion__c,
        Require_Customer_Acceptance__c,
        Calculation_Type__c,
        Rate__c,
        Fixed_Amount__c,
        Minimum_Revenue__c,
        Maximum_Incentive__c,
        Claim_Required__c,
        Approval_Required__c
      FROM Partner_Incentive_Policy__mdt
      WHERE Active__c = TRUE AND Incentive_Type__c = :incentiveType
      WITH SYSTEM_MODE
      ORDER BY Priority__c DESC NULLS LAST
      LIMIT 1
    ];
    if (!exactMatches.isEmpty()) {
      return exactMatches[0];
    }

    List<Partner_Incentive_Policy__mdt> fallback = [
      SELECT
        Policy_Key__c,
        Policy_Version__c,
        Required_Attribution_Type__c,
        Minimum_Attribution_Percentage__c,
        Require_Protection__c,
        Require_Implementation_Completion__c,
        Require_Customer_Acceptance__c,
        Calculation_Type__c,
        Rate__c,
        Fixed_Amount__c,
        Minimum_Revenue__c,
        Maximum_Incentive__c,
        Claim_Required__c,
        Approval_Required__c
      FROM Partner_Incentive_Policy__mdt
      WHERE Active__c = TRUE AND Incentive_Type__c = NULL
      WITH SYSTEM_MODE
      ORDER BY Priority__c DESC NULLS LAST
      LIMIT 1
    ];
    if (fallback.isEmpty()) {
      throw new PartnerSyncHandledException(
        'No active Partner Incentive Policy is configured.'
      );
    }
    return fallback[0];
  }

  private static Partner_Incentive__c selectAndCheckVersion(
    IncentiveCommand command
  ) {
    if (command.incentiveId == null) {
      throw new PartnerSyncHandledException(
        'An incentive is required for this command.'
      );
    }
    Partner_Incentive__c incentive = IncentiveSelector.selectForUpdate(
      command.incentiveId
    );
    Integer version = incentive.Version_Number__c == null
      ? 0
      : Integer.valueOf(incentive.Version_Number__c);
    if (command.expectedVersion == null || command.expectedVersion != version) {
      throw new PartnerSyncHandledException(
        'This incentive changed. Refresh before retrying.'
      );
    }
    return incentive;
  }

  private static Integer versionAfter(Partner_Incentive__c incentive) {
    return (incentive.Version_Number__c == null
        ? 0
        : Integer.valueOf(incentive.Version_Number__c)) + 1;
  }

  private static void publish(
    String eventType,
    Partner_Incentive__c incentive,
    String message
  ) {
    PlatformEventPublisherService.publish(
      eventType,
      incentive.Deal__c,
      'Deal_Registration__c',
      incentive.Partner_Account__c,
      message,
      'Info'
    );
  }
}
