@IsTest
private class DealAttributionEngineTest {
  @IsTest
  static void classifiesAsPartnerSourcedWhenOpportunityAgeWithinThreshold() {
    Deal_Attribution_Rule__mdt policy = new Deal_Attribution_Rule__mdt(
      Opportunity_Age_Threshold_Days__c = 5,
      Default_Attribution_Type__c = DealAttributionEngine.PARTNER_SOURCED
    );
    DealAttributionEngine.testPolicy = policy;

    Datetime submittedOn = Datetime.now();
    Datetime opportunityCreatedOn = submittedOn.addDays(-3);

    String result = DealAttributionEngine.classify(
      opportunityCreatedOn,
      submittedOn
    );

    Assert.areEqual(DealAttributionEngine.PARTNER_SOURCED, result);
  }

  @IsTest
  static void classifiesAsCoSellWhenOpportunityAgeExceedsThreshold() {
    Deal_Attribution_Rule__mdt policy = new Deal_Attribution_Rule__mdt(
      Opportunity_Age_Threshold_Days__c = 5,
      Default_Attribution_Type__c = DealAttributionEngine.PARTNER_SOURCED
    );
    DealAttributionEngine.testPolicy = policy;

    Datetime submittedOn = Datetime.now();
    Datetime opportunityCreatedOn = submittedOn.addDays(-10);

    String result = DealAttributionEngine.classify(
      opportunityCreatedOn,
      submittedOn
    );

    Assert.areEqual(DealAttributionEngine.CO_SELL, result);
  }

  @IsTest
  static void fallsBackToPolicyDefaultWhenOpportunityCreatedOnIsMissing() {
    Deal_Attribution_Rule__mdt policy = new Deal_Attribution_Rule__mdt(
      Opportunity_Age_Threshold_Days__c = 5,
      Default_Attribution_Type__c = DealAttributionEngine.CO_SELL
    );
    DealAttributionEngine.testPolicy = policy;

    String result = DealAttributionEngine.classify(null, Datetime.now());

    Assert.areEqual(DealAttributionEngine.CO_SELL, result);
  }

  @IsTest
  static void fallsBackToPolicyDefaultWhenSubmittedOnIsMissing() {
    Deal_Attribution_Rule__mdt policy = new Deal_Attribution_Rule__mdt(
      Opportunity_Age_Threshold_Days__c = 5,
      Default_Attribution_Type__c = DealAttributionEngine.CO_SELL
    );
    DealAttributionEngine.testPolicy = policy;

    String result = DealAttributionEngine.classify(Datetime.now(), null);

    Assert.areEqual(DealAttributionEngine.CO_SELL, result);
  }

  @IsTest
  static void treatsNullThresholdAsZero() {
    Deal_Attribution_Rule__mdt policy = new Deal_Attribution_Rule__mdt(
      Opportunity_Age_Threshold_Days__c = null,
      Default_Attribution_Type__c = DealAttributionEngine.PARTNER_SOURCED
    );
    DealAttributionEngine.testPolicy = policy;

    Datetime submittedOn = Datetime.now();
    Datetime opportunityCreatedOn = submittedOn.addDays(-1);

    String result = DealAttributionEngine.classify(
      opportunityCreatedOn,
      submittedOn
    );

    Assert.areEqual(DealAttributionEngine.CO_SELL, result);
  }

  @IsTest
  static void usesShippedDefaultMetadataWhenNoTestPolicyIsSet() {
    Datetime submittedOn = Datetime.now();
    Datetime opportunityCreatedOn = submittedOn.addDays(-30);

    String result = DealAttributionEngine.classify(
      opportunityCreatedOn,
      submittedOn
    );

    Assert.areEqual(DealAttributionEngine.CO_SELL, result);
  }
}
