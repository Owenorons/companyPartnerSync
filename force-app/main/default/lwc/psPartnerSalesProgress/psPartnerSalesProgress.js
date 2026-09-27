import { LightningElement, api, wire } from "lwc";
import getSalesProgress from "@salesforce/apex/DealOpportunityController.getSalesProgress";

export default class PsPartnerSalesProgress extends LightningElement {
  @api dealId;

  progress;
  error;
  loading = true;

  @wire(getSalesProgress, { dealId: "$dealId" })
  wiredProgress(result) {
    this.loading = false;

    if (result.data) {
      this.progress = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load sales progress."
      );
      this.progress = undefined;
    }
  }

  get hasProgress() {
    return Boolean(this.progress) && !this.error;
  }

  get stageLabel() {
    return this.progress?.stage || "Not set";
  }

  get amountLabel() {
    return this.formatCurrency(this.progress?.amount);
  }

  get closeDateLabel() {
    return this.formatDate(this.progress?.closeDate);
  }

  get statusBadgeVariant() {
    if (this.progress?.isWon) {
      return "success";
    }
    if (this.progress?.isClosed) {
      return "danger";
    }
    return "info";
  }

  formatCurrency(value) {
    if (value === null || value === undefined) {
      return "Not set";
    }
    return new Intl.NumberFormat("en-AU", {
      style: "currency",
      currency: "AUD",
      maximumFractionDigits: 0
    }).format(value);
  }

  formatDate(value) {
    if (!value) {
      return "Not set";
    }
    return new Intl.DateTimeFormat("en-AU", { dateStyle: "medium" }).format(
      new Date(value)
    );
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
