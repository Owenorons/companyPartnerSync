@IsTest
private class MDFCalculationEngineTest {
  @IsTest
  static void appliesRateAsAPercentageMatch() {
    MDFCalculationEngine.testRule = new MDF_Calculation_Rule__mdt(
      Rate__c = 0.5
    );

    Decimal eligible = MDFCalculationEngine.computeEligibleAmount(
      1000,
      'Webinar'
    );

    Assert.areEqual(500, eligible);
  }

  @IsTest
  static void clampsToCapWhenRateExceedsIt() {
    MDFCalculationEngine.testRule = new MDF_Calculation_Rule__mdt(
      Rate__c = 1,
      Cap__c = 300
    );

    Decimal eligible = MDFCalculationEngine.computeEligibleAmount(
      1000,
      'Event'
    );

    Assert.areEqual(300, eligible);
  }

  @IsTest
  static void blankRateDefaultsToFullMatch() {
    MDFCalculationEngine.testRule = new MDF_Calculation_Rule__mdt(
      Cap__c = 5000
    );

    Decimal eligible = MDFCalculationEngine.computeEligibleAmount(
      1000,
      'Other'
    );

    Assert.areEqual(1000, eligible);
  }

  @IsTest
  static void returnsNullWhenNoRuleMatches() {
    MDFCalculationEngine.testForceNoMatch = true;

    Decimal eligible = MDFCalculationEngine.computeEligibleAmount(
      1000,
      'Webinar'
    );

    Assert.isNull(eligible);
  }

  @IsTest
  static void returnsNullForNonPositiveRequestedAmount() {
    MDFCalculationEngine.testRule = new MDF_Calculation_Rule__mdt(
      Rate__c = 0.5
    );

    Assert.isNull(MDFCalculationEngine.computeEligibleAmount(0, 'Webinar'));
    Assert.isNull(MDFCalculationEngine.computeEligibleAmount(null, 'Webinar'));
    Assert.isNull(MDFCalculationEngine.computeEligibleAmount(-100, 'Webinar'));
  }

  @IsTest
  static void usesTheRealShippedDefaultRuleWhenNoOverrideIsSet() {
    // No testRule/testForceNoMatch set - exercises the real CMDT query
    // against the shipped MDF_Calculation_Rule.Default record (blank
    // Industry__c/Campaign_Type__c, Rate__c = 0.5, no Cap__c), proving the
    // matching query itself (not just the formula) works end to end.
    Decimal eligible = MDFCalculationEngine.computeEligibleAmount(
      2000,
      'Digital Advertising'
    );

    Assert.areEqual(1000, eligible);
  }
}
