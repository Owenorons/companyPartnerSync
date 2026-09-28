/*
 * Covers PartnerIncentiveEligibilityService.evaluate()'s pure guard chain
 * - each precondition independently blocks eligibility.
 */
@IsTest
private class PartnerIncentiveEligibilityServiceTest {
  @IsTest
  static void eligibleWhenEveryConditionIsSatisfied() {
    Assert.areEqual(
      PartnerIncentiveEligibilityService.ELIGIBLE,
      PartnerIncentiveEligibilityService.evaluate(
        true,
        true,
        true,
        false,
        false,
        false,
        false,
        50000,
        null
      )
    );
  }

  @IsTest
  static void ineligibleWhenAttributionNotConfirmed() {
    Assert.areEqual(
      PartnerIncentiveEligibilityService.INELIGIBLE,
      PartnerIncentiveEligibilityService.evaluate(
        false,
        true,
        true,
        false,
        false,
        false,
        false,
        50000,
        null
      )
    );
  }

  @IsTest
  static void ineligibleWhenAttributionTypeDoesNotMatch() {
    Assert.areEqual(
      PartnerIncentiveEligibilityService.INELIGIBLE,
      PartnerIncentiveEligibilityService.evaluate(
        true,
        false,
        true,
        false,
        false,
        false,
        false,
        50000,
        null
      )
    );
  }

  @IsTest
  static void ineligibleWhenBelowMinimumAttributionPercentage() {
    Assert.areEqual(
      PartnerIncentiveEligibilityService.INELIGIBLE,
      PartnerIncentiveEligibilityService.evaluate(
        true,
        true,
        false,
        false,
        false,
        false,
        false,
        50000,
        null
      )
    );
  }

  @IsTest
  static void ineligibleWhenProtectionRequiredButMissing() {
    Assert.areEqual(
      PartnerIncentiveEligibilityService.INELIGIBLE,
      PartnerIncentiveEligibilityService.evaluate(
        true,
        true,
        true,
        true,
        false,
        false,
        false,
        50000,
        null
      )
    );
  }

  @IsTest
  static void ineligibleWhenImplementationCompletionRequiredButMissing() {
    Assert.areEqual(
      PartnerIncentiveEligibilityService.INELIGIBLE,
      PartnerIncentiveEligibilityService.evaluate(
        true,
        true,
        true,
        false,
        false,
        true,
        false,
        50000,
        null
      )
    );
  }

  @IsTest
  static void ineligibleWhenBelowMinimumRevenue() {
    Assert.areEqual(
      PartnerIncentiveEligibilityService.INELIGIBLE,
      PartnerIncentiveEligibilityService.evaluate(
        true,
        true,
        true,
        false,
        false,
        false,
        false,
        5000,
        10000
      )
    );
  }
}
