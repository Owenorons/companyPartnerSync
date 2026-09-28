import { LightningElement, wire } from "lwc";
import getLatestSnapshot from "@salesforce/apex/ExecutiveCommandCenterController.getLatestSnapshot";
import getMetricDefinitions from "@salesforce/apex/ExecutiveCommandCenterController.getMetricDefinitions";
import getTrend from "@salesforce/apex/ExecutiveCommandCenterController.getTrend";
import exportSnapshotCsv from "@salesforce/apex/ExecutiveCommandCenterController.exportSnapshotCsv";

const TREND_DAYS = 30;

const VALUE_BY_METRIC_KEY = {
  Active_Partner_Count__c: (snapshot) => snapshot.activePartnerCount,
  Average_Health_Score__c: (snapshot) => snapshot.averageHealthScore,
  Total_Open_Deal_Count__c: (snapshot) => snapshot.totalOpenDealCount,
  Total_At_Risk_Deal_Count__c: (snapshot) => snapshot.totalAtRiskDealCount,
  Total_Active_Engagement_Count__c: (snapshot) =>
    snapshot.totalActiveEngagementCount,
  Total_At_Risk_Engagement_Count__c: (snapshot) =>
    snapshot.totalAtRiskEngagementCount,
  Total_Upcoming_Renewal_Count__c: (snapshot) =>
    snapshot.totalUpcomingRenewalCount,
  Total_Renewal_Value_At_Risk__c: (snapshot) =>
    snapshot.totalRenewalValueAtRisk,
  Total_Open_Expansion_Count__c: (snapshot) => snapshot.totalOpenExpansionCount,
  Total_Churned_Engagement_Count_Trailing_12mo__c: (snapshot) =>
    snapshot.totalChurnedEngagementCountTrailing12mo,
  Total_Revenue_Trailing_12mo__c: (snapshot) =>
    snapshot.totalRevenueTrailing12mo,
  Open_AI_Recommendation_Count__c: (snapshot) =>
    snapshot.openAiRecommendationCount
};

export default class PsExecutiveCommandCenter extends LightningElement {
  snapshot;
  metricDefinitions = [];
  trend = [];
  error;
  loading = true;
  exporting = false;

  @wire(getLatestSnapshot)
  wiredSnapshot({ data, error }) {
    this.loading = false;
    if (data) {
      this.snapshot = data;
      this.error = undefined;
    } else if (error) {
      this.error = this.getErrorMessage(
        error,
        "Unable to load the executive snapshot."
      );
      this.snapshot = undefined;
    }
  }

  @wire(getMetricDefinitions)
  wiredMetricDefinitions({ data, error }) {
    if (data) {
      this.metricDefinitions = data;
      this.error = undefined;
    } else if (error) {
      this.error = this.getErrorMessage(
        error,
        "Unable to load metric definitions."
      );
      this.metricDefinitions = [];
    }
  }

  @wire(getTrend, { days: TREND_DAYS })
  wiredTrend({ data, error }) {
    if (data) {
      this.trend = data;
      this.error = undefined;
    } else if (error) {
      this.error = this.getErrorMessage(
        error,
        "Unable to load the executive trend."
      );
      this.trend = [];
    }
  }

  get hasSnapshot() {
    return !!this.snapshot;
  }

  get hasMetricTiles() {
    return this.metricTiles.length > 0;
  }

  get metricTiles() {
    if (!this.snapshot) {
      return [];
    }
    return this.metricDefinitions.map((definition) => ({
      key: definition.Metric_Key__c,
      label: definition.Display_Label__c,
      value: this.formatValue(
        this.valueForMetricKey(definition.Metric_Key__c),
        definition.Format__c
      )
    }));
  }

  get hasTrend() {
    return this.trend.length > 0;
  }

  get trendRows() {
    return this.trend.map((row) => ({
      key: row.snapshotId || row.snapshotDate,
      snapshotDate: row.snapshotDate,
      activePartnerCount: row.activePartnerCount,
      averageHealthScoreLabel: this.formatValue(
        row.averageHealthScore,
        "Number"
      )
    }));
  }

  get narrative() {
    return this.snapshot?.narrative;
  }

  get hasNarrative() {
    return !!this.narrative;
  }

  valueForMetricKey(metricKey) {
    const resolver = VALUE_BY_METRIC_KEY[metricKey];
    return resolver ? resolver(this.snapshot) : undefined;
  }

  formatValue(value, format) {
    if (value === undefined || value === null) {
      return "-";
    }
    if (format === "Currency") {
      return new Intl.NumberFormat("en-AU", {
        style: "currency",
        currency: "AUD",
        maximumFractionDigits: 0
      }).format(Number(value));
    }
    if (format === "Percent") {
      return new Intl.NumberFormat("en-AU", {
        style: "percent",
        maximumFractionDigits: 0
      }).format(Number(value));
    }
    return new Intl.NumberFormat("en-AU").format(Number(value));
  }

  async handleExport() {
    this.exporting = true;
    try {
      const csv = await exportSnapshotCsv();
      const blob = new Blob([csv], { type: "text/csv" });
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = "executive-snapshot.csv";
      link.click();
      URL.revokeObjectURL(url);
      this.error = undefined;
    } catch (error) {
      this.error = this.getErrorMessage(
        error,
        "Unable to export the executive snapshot."
      );
    } finally {
      this.exporting = false;
    }
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
