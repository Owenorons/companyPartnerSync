import { LightningElement } from "lwc";
import getMyInsights from "@salesforce/apex/PartnerAIController.getMyInsights";

export default class PsAiInsightPanel extends LightningElement {
  insights = [];
  error;
  isLoading = true;

  connectedCallback() {
    this.loadInsights();
  }

  async loadInsights() {
    this.isLoading = true;
    this.error = undefined;

    try {
      const rows = await getMyInsights();
      this.insights = (rows || []).map((row) => this.toViewModel(row));
    } catch (error) {
      this.error = this.getErrorMessage(error);
      this.insights = [];
    } finally {
      this.isLoading = false;
    }
  }

  toViewModel(row) {
    const confidence = Number(row.confidence || 0);

    return {
      ...row,
      score: confidence ? Math.round(confidence) : "-",
      generatedLabel: this.formatDate(row.generatedOn),
      confidenceLabel: confidence ? `${Math.round(confidence)}%` : "Not set",
      confidenceStyle: `width: ${Math.min(confidence, 100)}%`
    };
  }

  formatDate(value) {
    if (!value) {
      return "Recently generated";
    }

    return new Intl.DateTimeFormat(undefined, {
      month: "short",
      day: "numeric",
      year: "numeric"
    }).format(new Date(value));
  }

  get hasInsights() {
    return this.insights.length > 0;
  }

  get showEmptyState() {
    return !this.isLoading && !this.error && !this.hasInsights;
  }

  getErrorMessage(error) {
    return (
      error?.body?.message ||
      error?.message ||
      "AI insights are not available right now."
    );
  }
}
