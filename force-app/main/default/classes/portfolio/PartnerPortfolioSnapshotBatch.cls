/**
 * Scheduled/batch job that computes one Partner_Portfolio_Snapshot__c per
 * active partner account per run - a genuine bulk design from day one, not
 * a retrofit: every count/sum is a single aggregate SOQL call grouped by
 * partner (a fixed, small number of queries regardless of chunk size),
 * mirroring AnalyticsSelector.selectKpiTotals()'s own "N queries
 * regardless of partner count" precedent. The health score is never
 * reimplemented - it's computed via
 * AnalyticsDomain.calculatePartnerKPI()/PartnerHealthScoringService.calculate(),
 * the exact same pure, no-SOQL path the existing partner KPI/leaderboard
 * feature already uses. Each run inserts fresh snapshot rows (a historical
 * series), never updates a prior run's rows.
 */
public with sharing class PartnerPortfolioSnapshotBatch implements Database.Batchable<SObject>, Schedulable {
  /**
   * Builds the query locator over active partner accounts.
   *
   * @param context Batch execution context (unused).
   * @return A query locator over Active partner Account rows.
   */
  public Database.QueryLocator start(Database.BatchableContext context) {
    return Database.getQueryLocator(
      [
        SELECT Id, MDF_Annual_Budget__c, MDF_Used__c
        FROM Account
        WHERE Is_Partner__c = TRUE
      ]
    );
  }

  /**
   * Computes and inserts one snapshot per partner account in scope, using
   * bulk aggregate queries throughout - no query is issued per partner.
   *
   * @param context Batch execution context (unused).
   * @param scope Batch of active partner Account rows to snapshot.
   */
  public void execute(Database.BatchableContext context, List<Account> scope) {
    Set<Id> partnerIds = new Set<Id>();
    Map<Id, Account> accountsById = new Map<Id, Account>();
    for (Account partner : scope) {
      partnerIds.add(partner.Id);
      accountsById.put(partner.Id, partner);
    }

    Map<Id, AnalyticsDomain.KpiTotals> kpiTotals = AnalyticsSelector.selectKpiTotals(
      partnerIds
    );

    Map<Id, Integer> openDealCounts = countByPartner(
      [
        SELECT Partner_Account__c partnerId, COUNT(Id) recordCount
        FROM Deal_Registration__c
        WHERE Partner_Account__c IN :partnerIds AND Status__c != 'Rejected'
        WITH SYSTEM_MODE
        GROUP BY Partner_Account__c
      ]
    );
    Map<Id, Integer> atRiskDealCounts = countByPartner(
      [
        SELECT Partner_Account__c partnerId, COUNT(Id) recordCount
        FROM Deal_Registration__c
        WHERE
          Partner_Account__c IN :partnerIds
          AND Lifecycle_Health__c = 'Blocked'
        WITH SYSTEM_MODE
        GROUP BY Partner_Account__c
      ]
    );
    Map<Id, Integer> activeEngagementCounts = countByPartner(
      [
        SELECT Primary_Partner__c partnerId, COUNT(Id) recordCount
        FROM Customer_Success_Engagement__c
        WHERE Primary_Partner__c IN :partnerIds AND Status__c = 'Active'
        WITH SYSTEM_MODE
        GROUP BY Primary_Partner__c
      ]
    );
    Map<Id, Integer> atRiskEngagementCounts = countByPartner(
      [
        SELECT Primary_Partner__c partnerId, COUNT(Id) recordCount
        FROM Customer_Success_Engagement__c
        WHERE
          Primary_Partner__c IN :partnerIds
          AND Health_Status__c IN ('At Risk', 'Critical')
        WITH SYSTEM_MODE
        GROUP BY Primary_Partner__c
      ]
    );
    Map<Id, Integer> upcomingRenewalCounts = countByPartner(
      [
        SELECT Primary_Partner__c partnerId, COUNT(Id) recordCount
        FROM Partner_Renewal__c
        WHERE
          Primary_Partner__c IN :partnerIds
          AND Status__c NOT IN (
            'Renewed',
            'Not Renewed',
            'Churned',
            'Cancelled'
          )
        WITH SYSTEM_MODE
        GROUP BY Primary_Partner__c
      ]
    );
    Map<Id, Decimal> renewalValueAtRisk = sumByPartner(
      [
        SELECT
          Primary_Partner__c partnerId,
          SUM(Current_Deal__r.Approved_Revenue__c) totalAmount
        FROM Partner_Renewal__c
        WHERE
          Primary_Partner__c IN :partnerIds
          AND Renewal_Health__c IN ('Watch', 'At Risk', 'Critical')
        WITH SYSTEM_MODE
        GROUP BY Primary_Partner__c
      ]
    );
    Map<Id, Integer> openExpansionCounts = countByPartner(
      [
        SELECT Primary_Partner__c partnerId, COUNT(Id) recordCount
        FROM Partner_Expansion__c
        WHERE
          Primary_Partner__c IN :partnerIds
          AND Status__c NOT IN ('Completed', 'Cancelled')
        WITH SYSTEM_MODE
        GROUP BY Primary_Partner__c
      ]
    );
    Datetime twelveMonthsAgo = System.now().addMonths(-12);
    Map<Id, Integer> churnedEngagementCounts = countByPartner(
      [
        SELECT Primary_Partner__c partnerId, COUNT(Id) recordCount
        FROM Customer_Success_Engagement__c
        WHERE
          Primary_Partner__c IN :partnerIds
          AND Status__c = 'Churned'
          AND Churned_On__c >= :twelveMonthsAgo.date()
        WITH SYSTEM_MODE
        GROUP BY Primary_Partner__c
      ]
    );
    Map<Id, Decimal> trailing12moRevenue = sumByPartner(
      [
        SELECT Partner_Account__c partnerId, SUM(Net_Amount__c) totalAmount
        FROM Deal_Revenue__c
        WHERE
          Partner_Account__c IN :partnerIds
          AND Status__c = 'Confirmed'
          AND Revenue_Date__c >= :twelveMonthsAgo.date()
        WITH SYSTEM_MODE
        GROUP BY Partner_Account__c
      ]
    );

    List<Partner_Portfolio_Snapshot__c> snapshots = new List<Partner_Portfolio_Snapshot__c>();
    Date today = System.today();
    for (Id partnerId : partnerIds) {
      PartnerKPIDTO kpi = AnalyticsDomain.calculatePartnerKPI(
        kpiTotals.get(partnerId),
        accountsById.get(partnerId)
      );
      Decimal healthScore = PartnerHealthScoringService.calculate(kpi);

      snapshots.add(
        new Partner_Portfolio_Snapshot__c(
          Partner_Account__c = partnerId,
          Snapshot_Date__c = today,
          Health_Score__c = healthScore,
          Health_Label__c = PartnerHealthScoringService.healthLabel(
            healthScore
          ),
          Open_Deal_Count__c = orZero(openDealCounts.get(partnerId)),
          At_Risk_Deal_Count__c = orZero(atRiskDealCounts.get(partnerId)),
          Active_Engagement_Count__c = orZero(
            activeEngagementCounts.get(partnerId)
          ),
          At_Risk_Engagement_Count__c = orZero(
            atRiskEngagementCounts.get(partnerId)
          ),
          Upcoming_Renewal_Count__c = orZero(
            upcomingRenewalCounts.get(partnerId)
          ),
          Renewal_Value_At_Risk__c = orZeroDecimal(
            renewalValueAtRisk.get(partnerId)
          ),
          Open_Expansion_Count__c = orZero(openExpansionCounts.get(partnerId)),
          Churned_Engagement_Count_Trailing_12mo__c = orZero(
            churnedEngagementCounts.get(partnerId)
          ),
          Total_Revenue_Trailing_12mo__c = orZeroDecimal(
            trailing12moRevenue.get(partnerId)
          )
        )
      );
    }

    if (!snapshots.isEmpty()) {
      Database.insert(snapshots, false, AccessLevel.SYSTEM_MODE);
    }
  }

  /**
   * No post-processing is required after this batch runs.
   *
   * @param context Batch execution context (unused).
   */
  public void finish(Database.BatchableContext context) {
  }

  /**
   * Scheduled entry point: launches this class as a batch job. Chunk size
   * 200 is safe: every count/sum above is a fixed, small number of bulk
   * aggregate SOQL calls per chunk (about 11 total, matching
   * AnalyticsSelector.selectKpiTotals()'s own "N queries regardless of
   * partner count" shape), not one query per partner - well under the
   * 100-SOQL limit even at 200 partners in one chunk, and within
   * selectKpiTotals()'s own 1,000-partner-per-call cap.
   *
   * @param context Scheduled execution context (unused).
   */
  public void execute(SchedulableContext context) {
    Database.executeBatch(new PartnerPortfolioSnapshotBatch(), 200);
  }

  private static Map<Id, Integer> countByPartner(
    List<AggregateResult> results
  ) {
    Map<Id, Integer> counts = new Map<Id, Integer>();
    for (AggregateResult row : results) {
      counts.put((Id) row.get('partnerId'), (Integer) row.get('recordCount'));
    }
    return counts;
  }

  private static Map<Id, Decimal> sumByPartner(List<AggregateResult> results) {
    Map<Id, Decimal> sums = new Map<Id, Decimal>();
    for (AggregateResult row : results) {
      sums.put((Id) row.get('partnerId'), (Decimal) row.get('totalAmount'));
    }
    return sums;
  }

  private static Integer orZero(Integer value) {
    return value == null ? 0 : value;
  }

  private static Decimal orZeroDecimal(Decimal value) {
    return value == null ? 0 : value;
  }
}
