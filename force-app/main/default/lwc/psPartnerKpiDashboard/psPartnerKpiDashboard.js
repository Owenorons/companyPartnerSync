import { LightningElement, wire } from "lwc";
import getMyKPI from "@salesforce/apex/AnalyticsController.getMyKPI";

export default class PsPartnerKpiDashboard extends LightningElement {
  kpi;
  error;
  loading = true;

  @wire(getMyKPI)
  wiredKpi({ data, error }) {
    this.loading = false;
    if (data) {
      this.kpi = data;
      this.error = undefined;
    } else if (error) {
      this.kpi = undefined;
      this.error =
        error?.body?.message ||
        error?.message ||
        "Unable to load partner performance.";
    }
  }

  get hasKpi() {
    return Boolean(this.kpi);
  }

  get score() {
    return Math.round(Number(this.kpi?.healthScore || 0));
  }

  get scoreLabel() {
    return `${this.score}/100`;
  }

  get pipelineLabel() {
    return this.formatCurrency(this.kpi?.totalPipeline);
  }

  get revenueLabel() {
    return this.formatCurrency(this.kpi?.totalRevenue);
  }

  get leadConversionLabel() {
    return this.formatPercent(this.kpi?.leadConversionRate);
  }

  get dealWinLabel() {
    return this.formatPercent(this.kpi?.dealWinRate);
  }

  get mdfLabel() {
    return this.formatPercent(this.kpi?.mdfUtilisationRate);
  }

  get healthSignals() {
    return (this.kpi?.healthSignals || []).map((label, index) => ({
      key: `signal-${index}`,
      label
    }));
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("en-AU", {
      style: "currency",
      currency: "AUD",
      maximumFractionDigits: 0
    }).format(Number(value || 0));
  }

  formatPercent(value) {
    return new Intl.NumberFormat("en-AU", {
      style: "percent",
      maximumFractionDigits: 0
    }).format(Number(value || 0));
  }
}
