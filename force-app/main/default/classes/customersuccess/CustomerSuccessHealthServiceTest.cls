/*
 * Covers CustomerSuccessHealthService.computeHealth(): each threshold
 * branch (Healthy/Watch/At Risk/Critical), a metric with no data is
 * excluded rather than guessed, and a metric marked "Treat As Critical"
 * contributes a 0 instead of being excluded when missing.
 */
@IsTest
private class CustomerSuccessHealthServiceTest {
  @IsTest
  static void scoreAboveHealthyThresholdIsHealthy() {
    CustomerSuccessHealthService.HealthResult result = CustomerSuccessHealthService.computeHealth(
      policyRows(),
      new Map<String, Decimal>{ 'Adoption' => 90 }
    );
    Assert.areEqual('Healthy', result.status);
  }

  @IsTest
  static void scoreBetweenWatchAndHealthyIsWatch() {
    CustomerSuccessHealthService.HealthResult result = CustomerSuccessHealthService.computeHealth(
      policyRows(),
      new Map<String, Decimal>{ 'Adoption' => 65 }
    );
    Assert.areEqual('Watch', result.status);
  }

  @IsTest
  static void scoreBetweenAtRiskAndWatchIsAtRisk() {
    CustomerSuccessHealthService.HealthResult result = CustomerSuccessHealthService.computeHealth(
      policyRows(),
      new Map<String, Decimal>{ 'Adoption' => 45 }
    );
    Assert.areEqual('At Risk', result.status);
  }

  @IsTest
  static void scoreBelowAtRiskThresholdIsCritical() {
    CustomerSuccessHealthService.HealthResult result = CustomerSuccessHealthService.computeHealth(
      policyRows(),
      new Map<String, Decimal>{ 'Adoption' => 10 }
    );
    Assert.areEqual('Critical', result.status);
  }

  @IsTest
  static void missingMetricIsExcludedNotGuessed() {
    List<Customer_Success_Health_Policy__mdt> rows = new List<Customer_Success_Health_Policy__mdt>{
      policyRow('Adoption', 50, 'Exclude'),
      policyRow('Support Volume', 50, 'Exclude')
    };

    CustomerSuccessHealthService.HealthResult result = CustomerSuccessHealthService.computeHealth(
      rows,
      new Map<String, Decimal>{ 'Adoption' => 90 }
    );

    Assert.areEqual('Healthy', result.status);
    Assert.isTrue(result.explanation.contains('Excluded'));
    Assert.isTrue(result.explanation.contains('Support Volume'));
  }

  @IsTest
  static void missingMetricTreatedAsCriticalContributesZero() {
    List<Customer_Success_Health_Policy__mdt> rows = new List<Customer_Success_Health_Policy__mdt>{
      policyRow('Adoption', 50, 'Exclude'),
      policyRow('Support Volume', 50, 'Treat As Critical')
    };

    CustomerSuccessHealthService.HealthResult result = CustomerSuccessHealthService.computeHealth(
      rows,
      new Map<String, Decimal>{ 'Adoption' => 90 }
    );

    Assert.areEqual(45, result.score);
  }

  @IsTest
  static void noUsableMetricsIsNotAssessed() {
    List<Customer_Success_Health_Policy__mdt> rows = new List<Customer_Success_Health_Policy__mdt>{
      policyRow('Adoption', 50, 'Exclude')
    };

    CustomerSuccessHealthService.HealthResult result = CustomerSuccessHealthService.computeHealth(
      rows,
      new Map<String, Decimal>()
    );

    Assert.areEqual('Not Assessed', result.status);
  }

  private static List<Customer_Success_Health_Policy__mdt> policyRows() {
    return new List<Customer_Success_Health_Policy__mdt>{
      policyRow('Adoption', 100, 'Exclude')
    };
  }

  private static Customer_Success_Health_Policy__mdt policyRow(
    String metric,
    Decimal weight,
    String missingDataBehaviour
  ) {
    return new Customer_Success_Health_Policy__mdt(
      Metric__c = metric,
      Weight__c = weight,
      Healthy_Threshold__c = 80,
      Watch_Threshold__c = 60,
      At_Risk_Threshold__c = 40,
      Critical_Threshold__c = 20,
      Missing_Data_Behaviour__c = missingDataBehaviour
    );
  }
}
