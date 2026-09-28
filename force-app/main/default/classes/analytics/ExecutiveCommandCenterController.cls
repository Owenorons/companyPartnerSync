/**
 * Aura controller surface for Sprint 44's Executive Command Center. Pure
 * pass-through/exception-translation layer over Executive_Snapshot__c and
 * Metric_Definition__mdt - no business logic here. Reuses the existing
 * PartnerSync_View_Executive_Analytics/PartnerSync_Export_Executive_Reports
 * permissions rather than creating new ones (the export permission
 * previously had no real Apex consumer anywhere in this codebase -
 * exportSnapshotCsv() closes that gap).
 */
public with sharing class ExecutiveCommandCenterController {
  private static final Integer MAX_TREND_DAYS = 90;

  /**
   * Loads the most recently computed Executive_Snapshot__c.
   *
   * @return The latest snapshot, sanitized, or null if none has been computed yet.
   */
  @AuraEnabled(cacheable=true)
  public static ExecutiveSnapshotDTO getLatestSnapshot() {
    try {
      PartnerPermissionService.assertCanViewExecutiveAnalytics();
      List<Executive_Snapshot__c> rows = [
        SELECT
          Snapshot_Date__c,
          Active_Partner_Count__c,
          Average_Health_Score__c,
          Total_Open_Deal_Count__c,
          Total_At_Risk_Deal_Count__c,
          Total_Active_Engagement_Count__c,
          Total_At_Risk_Engagement_Count__c,
          Total_Upcoming_Renewal_Count__c,
          Total_Renewal_Value_At_Risk__c,
          Total_Open_Expansion_Count__c,
          Total_Churned_Engagement_Count_Trailing_12mo__c,
          Total_Revenue_Trailing_12mo__c,
          Open_AI_Recommendation_Count__c,
          Narrative__c,
          Computed_On__c
        FROM Executive_Snapshot__c
        WITH SYSTEM_MODE
        ORDER BY Snapshot_Date__c DESC
        LIMIT 1
      ];
      return rows.isEmpty() ? null : toDTO(rows[0]);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ExecutiveCommandCenterController',
        'Unable to load the executive snapshot.',
        'Unable to load the executive snapshot.',
        ex
      );
    }
  }

  /**
   * Loads the metric tile definitions (label/category/format/order),
   * display metadata only - never dynamically invoked to build SOQL.
   *
   * @return Active metric definitions, in display order.
   */
  @AuraEnabled(cacheable=true)
  public static List<Metric_Definition__mdt> getMetricDefinitions() {
    try {
      PartnerPermissionService.assertCanViewExecutiveAnalytics();
      return [
        SELECT
          Metric_Key__c,
          Display_Label__c,
          Category__c,
          Format__c,
          Display_Order__c
        FROM Metric_Definition__mdt
        WHERE Active__c = TRUE
        WITH SYSTEM_MODE
        ORDER BY Display_Order__c ASC NULLS LAST
      ];
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ExecutiveCommandCenterController',
        'Unable to load metric definitions.',
        'Unable to load metric definitions.',
        ex
      );
    }
  }

  /**
   * Loads the last N days of Executive_Snapshot__c, oldest first, for a
   * simple historical trend view.
   *
   * @param days Number of days of history to load, capped at 90.
   * @return Up to `days` snapshots, oldest first.
   */
  @AuraEnabled(cacheable=true)
  public static List<ExecutiveSnapshotDTO> getTrend(Integer days) {
    try {
      PartnerPermissionService.assertCanViewExecutiveAnalytics();
      Integer boundedDays = days == null ||
        days > MAX_TREND_DAYS
        ? MAX_TREND_DAYS
        : Math.max(1, days);
      List<ExecutiveSnapshotDTO> results = new List<ExecutiveSnapshotDTO>();
      List<Executive_Snapshot__c> rows = [
        SELECT
          Snapshot_Date__c,
          Active_Partner_Count__c,
          Average_Health_Score__c,
          Total_Open_Deal_Count__c,
          Total_At_Risk_Deal_Count__c,
          Total_Active_Engagement_Count__c,
          Total_At_Risk_Engagement_Count__c,
          Total_Upcoming_Renewal_Count__c,
          Total_Renewal_Value_At_Risk__c,
          Total_Open_Expansion_Count__c,
          Total_Churned_Engagement_Count_Trailing_12mo__c,
          Total_Revenue_Trailing_12mo__c,
          Open_AI_Recommendation_Count__c,
          Narrative__c,
          Computed_On__c
        FROM Executive_Snapshot__c
        WITH SYSTEM_MODE
        ORDER BY Snapshot_Date__c DESC
        LIMIT :boundedDays
      ];
      for (Integer index = rows.size() - 1; index >= 0; index--) {
        results.add(toDTO(rows[index]));
      }
      return results;
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ExecutiveCommandCenterController',
        'Unable to load the executive trend.',
        'Unable to load the executive trend.',
        ex
      );
    }
  }

  /**
   * Builds a plain CSV of the latest snapshot's metrics, labeled via
   * Metric_Definition__mdt, for client-side download.
   *
   * @return A CSV string with a header row and one data row.
   */
  @AuraEnabled
  public static String exportSnapshotCsv() {
    try {
      PartnerPermissionService.assertCanExportExecutiveReports();
      ExecutiveSnapshotDTO snapshot = getLatestSnapshot();
      if (snapshot == null) {
        throw new PartnerSyncHandledException(
          'No executive snapshot has been computed yet.'
        );
      }
      Map<String, Object> valuesByKey = new Map<String, Object>{
        'Active_Partner_Count__c' => snapshot.activePartnerCount,
        'Average_Health_Score__c' => snapshot.averageHealthScore,
        'Total_Open_Deal_Count__c' => snapshot.totalOpenDealCount,
        'Total_At_Risk_Deal_Count__c' => snapshot.totalAtRiskDealCount,
        'Total_Active_Engagement_Count__c' => snapshot.totalActiveEngagementCount,
        'Total_At_Risk_Engagement_Count__c' => snapshot.totalAtRiskEngagementCount,
        'Total_Upcoming_Renewal_Count__c' => snapshot.totalUpcomingRenewalCount,
        'Total_Renewal_Value_At_Risk__c' => snapshot.totalRenewalValueAtRisk,
        'Total_Open_Expansion_Count__c' => snapshot.totalOpenExpansionCount,
        'Total_Churned_Engagement_Count_Trailing_12mo__c' => snapshot.totalChurnedEngagementCountTrailing12mo,
        'Total_Revenue_Trailing_12mo__c' => snapshot.totalRevenueTrailing12mo,
        'Open_AI_Recommendation_Count__c' => snapshot.openAiRecommendationCount
      };

      List<String> headerCells = new List<String>{ 'Snapshot Date' };
      List<String> valueCells = new List<String>{
        String.valueOf(snapshot.snapshotDate)
      };
      for (Metric_Definition__mdt definition : getMetricDefinitions()) {
        headerCells.add(csvEscape(definition.Display_Label__c));
        Object value = valuesByKey.get(definition.Metric_Key__c);
        valueCells.add(value == null ? '' : String.valueOf(value));
      }

      return String.join(headerCells, ',') +
        '\n' +
        String.join(valueCells, ',');
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'ExecutiveCommandCenterController',
        'Unable to export the executive snapshot.',
        'Unable to export the executive snapshot.',
        ex
      );
    }
  }

  private static String csvEscape(String value) {
    if (String.isBlank(value)) {
      return '';
    }
    return value.contains(',') ? '"' + value + '"' : value;
  }

  private static ExecutiveSnapshotDTO toDTO(Executive_Snapshot__c snapshot) {
    ExecutiveSnapshotDTO dto = new ExecutiveSnapshotDTO();
    dto.snapshotId = snapshot.Id;
    dto.snapshotDate = snapshot.Snapshot_Date__c;
    dto.activePartnerCount = (Integer) snapshot.Active_Partner_Count__c;
    dto.averageHealthScore = snapshot.Average_Health_Score__c;
    dto.totalOpenDealCount = (Integer) snapshot.Total_Open_Deal_Count__c;
    dto.totalAtRiskDealCount = (Integer) snapshot.Total_At_Risk_Deal_Count__c;
    dto.totalActiveEngagementCount = (Integer) snapshot.Total_Active_Engagement_Count__c;
    dto.totalAtRiskEngagementCount = (Integer) snapshot.Total_At_Risk_Engagement_Count__c;
    dto.totalUpcomingRenewalCount = (Integer) snapshot.Total_Upcoming_Renewal_Count__c;
    dto.totalRenewalValueAtRisk = snapshot.Total_Renewal_Value_At_Risk__c;
    dto.totalOpenExpansionCount = (Integer) snapshot.Total_Open_Expansion_Count__c;
    dto.totalChurnedEngagementCountTrailing12mo = (Integer) snapshot.Total_Churned_Engagement_Count_Trailing_12mo__c;
    dto.totalRevenueTrailing12mo = snapshot.Total_Revenue_Trailing_12mo__c;
    dto.openAiRecommendationCount = (Integer) snapshot.Open_AI_Recommendation_Count__c;
    dto.narrative = snapshot.Narrative__c;
    dto.computedOn = snapshot.Computed_On__c;
    return dto;
  }
}
