/**
 * Computes and persists Customer_Success_Engagement__c.Health_Status__c
 * from Customer_Success_Health_Policy__mdt: a weighted score across
 * whatever metrics currently have real data (doc section 42.14 - a metric
 * with no observed value is tolerated, never fabricated). Same
 * recompute/pure-core split as ImplementationHealthService: recompute() is
 * for single-engagement call sites (CustomerSuccessRiskCommandService.raise()/
 * resolve()); computeHealth() is the pure, bulk-safe core.
 *
 * Today the only real signal available is open Customer_Success_Risk__c
 * severity (fed in as the 'Open Risk Severity' metric) - Adoption/Support
 * Volume have no real data source yet in this org (Known Adaptation: no
 * usage/support-ticket integration exists) and are deliberately left
 * missing rather than guessed, tolerated per each metric row's own
 * Missing_Data_Behaviour__c.
 */
public without sharing class CustomerSuccessHealthService {
  @TestVisible
  private static List<Customer_Success_Health_Policy__mdt> testPolicyRows;

  public class HealthResult {
    public Decimal score;
    public String status;
    public String explanation;
  }

  /**
   * Recomputes and, if changed, persists a single engagement's health.
   * Not for bulk/batch use.
   *
   * @param engagementId Id of the engagement to recompute.
   */
  public static void recompute(Id engagementId) {
    List<Customer_Success_Engagement__c> rows = [
      SELECT Id, Health_Status__c, Health_Score__c, Health_Policy_Key__c
      FROM Customer_Success_Engagement__c
      WHERE Id = :engagementId
      WITH SYSTEM_MODE
    ];
    if (rows.isEmpty()) {
      return;
    }
    Customer_Success_Engagement__c engagement = rows[0];

    String policyKey = String.isBlank(engagement.Health_Policy_Key__c)
      ? 'Default'
      : engagement.Health_Policy_Key__c;
    Map<String, Decimal> metricValues = new Map<String, Decimal>{
      'Open Risk Severity' => openRiskSeverityScore(engagementId)
    };

    HealthResult result = computeHealth(
      resolvePolicyRows(policyKey),
      metricValues
    );
    if (
      engagement.Health_Status__c == result.status &&
      engagement.Health_Score__c == result.score
    ) {
      return;
    }

    Database.update(
      new Customer_Success_Engagement__c(
        Id = engagementId,
        Health_Status__c = result.status,
        Health_Score__c = result.score,
        Health_Calculated_On__c = System.now(),
        Health_Policy_Key__c = policyKey,
        Health_Explanation__c = result.explanation,
        Health_Snapshot__c = JSON.serialize(metricValues)
      ),
      AccessLevel.SYSTEM_MODE
    );

    if (result.status == 'At Risk' || result.status == 'Critical') {
      PlatformEventPublisherService.publish(
        'CustomerHealthChanged',
        engagementId,
        'Customer_Success_Engagement__c',
        null,
        'A customer success engagement health changed to ' +
          result.status +
          '.',
        result.status == 'Critical' ? 'Error' : 'Warning'
      );
    }
  }

  /**
   * Pure computation of overall health from a policy's metric rows and
   * whatever metric values are actually available - no SOQL. A metric with
   * no value in metricValues is tolerated according to its own
   * Missing_Data_Behaviour__c: 'Treat As Critical' contributes a 0, anything
   * else (including blank/unset) excludes that metric's weight from the
   * denominator entirely rather than guessing a value.
   *
   * @param policyRows The active policy's metric rows (one per metric, sharing a Policy_Key__c).
   * @param metricValues Metric name to 0-100 score, for metrics with real data.
   * @return The computed score/status/explanation.
   */
  public static HealthResult computeHealth(
    List<Customer_Success_Health_Policy__mdt> policyRows,
    Map<String, Decimal> metricValues
  ) {
    HealthResult result = new HealthResult();
    if (policyRows == null || policyRows.isEmpty()) {
      result.status = 'Not Assessed';
      result.explanation = 'No active health policy configured.';
      return result;
    }

    Decimal weightedSum = 0;
    Decimal totalWeight = 0;
    List<String> included = new List<String>();
    List<String> excluded = new List<String>();

    for (Customer_Success_Health_Policy__mdt row : policyRows) {
      Decimal weight = row.Weight__c == null ? 0 : row.Weight__c;
      Decimal value = metricValues.get(row.Metric__c);
      if (value == null) {
        if (row.Missing_Data_Behaviour__c == 'Treat As Critical') {
          weightedSum += 0;
          totalWeight += weight;
          included.add(row.Metric__c + ' (missing, treated as critical)');
        } else {
          excluded.add(row.Metric__c);
        }
        continue;
      }
      weightedSum += value * weight;
      totalWeight += weight;
      included.add(row.Metric__c);
    }

    if (totalWeight == 0) {
      result.status = 'Not Assessed';
      result.explanation = 'No metrics with usable data.';
      return result;
    }

    result.score = (weightedSum / totalWeight).setScale(2);
    Customer_Success_Health_Policy__mdt thresholds = policyRows[0];
    result.status = statusForScore(result.score, thresholds);
    result.explanation =
      'Included: ' +
      String.join(included, ', ') +
      (excluded.isEmpty()
        ? ''
        : '. Excluded (no data): ' + String.join(excluded, ', '));
    return result;
  }

  private static String statusForScore(
    Decimal score,
    Customer_Success_Health_Policy__mdt thresholds
  ) {
    Decimal healthy = thresholds.Healthy_Threshold__c == null
      ? 80
      : thresholds.Healthy_Threshold__c;
    Decimal watch = thresholds.Watch_Threshold__c == null
      ? 60
      : thresholds.Watch_Threshold__c;
    Decimal atRisk = thresholds.At_Risk_Threshold__c == null
      ? 40
      : thresholds.At_Risk_Threshold__c;

    if (score >= healthy) {
      return 'Healthy';
    }
    if (score >= watch) {
      return 'Watch';
    }
    if (score >= atRisk) {
      return 'At Risk';
    }
    return 'Critical';
  }

  // 100 with no open risk down to a floor of 0 once Critical/High risks
  // accumulate - a simple, real signal rather than a fabricated one.
  private static Decimal openRiskSeverityScore(Id engagementId) {
    Integer criticalCount = 0;
    Integer highCount = 0;
    Integer otherCount = 0;
    for (AggregateResult result : [
      SELECT Severity__c sev, COUNT(Id) cnt
      FROM Customer_Success_Risk__c
      WHERE
        Customer_Success_Engagement__c = :engagementId
        AND Status__c NOT IN ('Resolved', 'Accepted', 'Closed')
      WITH SYSTEM_MODE
      GROUP BY Severity__c
    ]) {
      String severity = (String) result.get('sev');
      Integer count = (Integer) result.get('cnt');
      if (severity == 'Critical') {
        criticalCount = count;
      } else if (severity == 'High') {
        highCount = count;
      } else {
        otherCount = count;
      }
    }
    Decimal score =
      100 -
      (criticalCount * 70) -
      (highCount * 40) -
      (otherCount * 10);
    return score < 0 ? 0 : score;
  }

  private static List<Customer_Success_Health_Policy__mdt> resolvePolicyRows(
    String policyKey
  ) {
    if (Test.isRunningTest() && testPolicyRows != null) {
      return testPolicyRows;
    }
    List<Customer_Success_Health_Policy__mdt> rows = new List<Customer_Success_Health_Policy__mdt>();
    for (
      Customer_Success_Health_Policy__mdt row : Customer_Success_Health_Policy__mdt.getAll()
        .values()
    ) {
      if (row.Active__c == true && row.Policy_Key__c == policyKey) {
        rows.add(row);
      }
    }
    return rows;
  }
}
