/**
 * Computes the org-wide Executive_Snapshot__c for a day by aggregating
 * that day's already-computed Partner_Portfolio_Snapshot__c rows (Sprint
 * 43) - a "snapshot of snapshots," never a second pass over every
 * transactional table. Deliberately a plain Schedulable, not
 * Database.Batchable: Partner_Portfolio_Snapshot__c is already bounded to
 * one row per active partner per day (Sprint 43's own bulk-safe design),
 * so a single aggregate SOQL call (no GROUP BY - one summary row) computes
 * the whole thing in one transaction. Idempotent per day: re-running for a
 * day that already has a row updates that row rather than duplicating it.
 * Intended to run on a schedule offset after PartnerPortfolioSnapshotBatch
 * completes (a real, documented dependency - see the closing review doc;
 * not automated via job chaining, to keep this simple and inspectable).
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class ExecutiveSnapshotBatch implements Schedulable {
  /**
   * Computes and upserts today's Executive_Snapshot__c row.
   *
   * @return The computed (inserted or updated) snapshot.
   */
  public static Executive_Snapshot__c compute() {
    Date today = System.today();

    AggregateResult[] results = [
      SELECT
        COUNT(Id) partnerCount,
        AVG(Health_Score__c) avgHealth,
        SUM(Open_Deal_Count__c) openDeals,
        SUM(At_Risk_Deal_Count__c) atRiskDeals,
        SUM(Active_Engagement_Count__c) activeEngagements,
        SUM(At_Risk_Engagement_Count__c) atRiskEngagements,
        SUM(Upcoming_Renewal_Count__c) upcomingRenewals,
        SUM(Renewal_Value_At_Risk__c) renewalValueAtRisk,
        SUM(Open_Expansion_Count__c) openExpansions,
        SUM(Churned_Engagement_Count_Trailing_12mo__c) churnedEngagements,
        SUM(Total_Revenue_Trailing_12mo__c) totalRevenue
      FROM Partner_Portfolio_Snapshot__c
      WHERE Snapshot_Date__c = :today
      WITH SYSTEM_MODE
    ];
    AggregateResult totals = results[0];

    Integer openRecommendationCount = [
      SELECT COUNT()
      FROM AI_Recommendation__c
      WHERE Status__c = 'Proposed'
    ];

    List<Executive_Snapshot__c> existing = [
      SELECT Id
      FROM Executive_Snapshot__c
      WHERE Snapshot_Date__c = :today
      WITH SYSTEM_MODE
      LIMIT 1
    ];
    Executive_Snapshot__c snapshot = existing.isEmpty()
      ? new Executive_Snapshot__c(Snapshot_Date__c = today)
      : existing[0];

    snapshot.Active_Partner_Count__c = (Integer) totals.get('partnerCount');
    snapshot.Average_Health_Score__c = orZeroDecimal(
      (Decimal) totals.get('avgHealth')
    );
    snapshot.Total_Open_Deal_Count__c = orZero(
      (Integer) totals.get('openDeals')
    );
    snapshot.Total_At_Risk_Deal_Count__c = orZero(
      (Integer) totals.get('atRiskDeals')
    );
    snapshot.Total_Active_Engagement_Count__c = orZero(
      (Integer) totals.get('activeEngagements')
    );
    snapshot.Total_At_Risk_Engagement_Count__c = orZero(
      (Integer) totals.get('atRiskEngagements')
    );
    snapshot.Total_Upcoming_Renewal_Count__c = orZero(
      (Integer) totals.get('upcomingRenewals')
    );
    snapshot.Total_Renewal_Value_At_Risk__c = orZeroDecimal(
      (Decimal) totals.get('renewalValueAtRisk')
    );
    snapshot.Total_Open_Expansion_Count__c = orZero(
      (Integer) totals.get('openExpansions')
    );
    snapshot.Total_Churned_Engagement_Count_Trailing_12mo__c = orZero(
      (Integer) totals.get('churnedEngagements')
    );
    snapshot.Total_Revenue_Trailing_12mo__c = orZeroDecimal(
      (Decimal) totals.get('totalRevenue')
    );
    snapshot.Open_AI_Recommendation_Count__c = openRecommendationCount;
    snapshot.Computed_On__c = System.now();

    if (existing.isEmpty()) {
      Database.insert(snapshot, AccessLevel.SYSTEM_MODE);
    } else {
      Database.update(snapshot, AccessLevel.SYSTEM_MODE);
    }

    PlatformEventPublisherService.publish(
      'ExecutiveSnapshotComputed',
      snapshot.Id,
      'Executive_Snapshot__c',
      null,
      'The executive snapshot was computed.',
      'Info'
    );

    return snapshot;
  }

  /**
   * Scheduled entry point.
   *
   * @param context Scheduled execution context (unused).
   */
  public void execute(SchedulableContext context) {
    compute();
  }

  private static Integer orZero(Integer value) {
    return value == null ? 0 : value;
  }

  private static Decimal orZeroDecimal(Decimal value) {
    return value == null ? 0 : value;
  }
}
