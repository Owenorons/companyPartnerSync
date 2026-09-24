import { LightningElement } from "lwc";
import getMyInsights from "@salesforce/apex/PartnerAIController.getMyInsights";
import getInsightTypes from "@salesforce/apex/PartnerAIController.getInsightTypes";
import submitInsightRequest from "@salesforce/apex/PartnerAIController.submitInsightRequest";
import getMyInsightRequests from "@salesforce/apex/PartnerAIController.getMyInsightRequests";

export default class PsAiInsightPanel extends LightningElement {
  insights = [];
  error;
  isLoading = true;

  insightTypeOptions = [];
  myRequests = [];
  requestInsightType;
  requestNotes = "";
  submittingRequest = false;
  requestError;
  requestConfirmation;

  connectedCallback() {
    this.loadInsights();
    this.loadInsightTypes();
    this.loadMyRequests();
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

  async loadInsightTypes() {
    try {
      const types = await getInsightTypes();
      this.insightTypeOptions = (types || []).map((type) => ({
        label: type.label,
        value: type.developerName
      }));
    } catch {
      // Non-fatal: the request form just won't have options to pick from.
      this.insightTypeOptions = [];
    }
  }

  async loadMyRequests() {
    try {
      this.myRequests = (await getMyInsightRequests()) || [];
    } catch {
      this.myRequests = [];
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

  get isRequestDisabled() {
    return this.submittingRequest || !this.requestInsightType;
  }

  get hasMyRequests() {
    return this.myRequests.length > 0;
  }

  get myRequestRows() {
    return this.myRequests.map((request) => ({
      ...request,
      statusClass:
        request.status === "New"
          ? "ps-badge ps-badge-warning"
          : "ps-badge ps-badge-success"
    }));
  }

  handleRequestTypeChange(event) {
    this.requestInsightType = event.detail.value;
  }

  handleRequestNotesChange(event) {
    this.requestNotes = event.target.value || "";
  }

  async handleSubmitRequest() {
    if (this.isRequestDisabled) {
      return;
    }

    this.submittingRequest = true;
    this.requestError = undefined;
    this.requestConfirmation = undefined;

    try {
      await submitInsightRequest({
        insightType: this.requestInsightType,
        notes: this.requestNotes
      });
      this.requestConfirmation =
        "Request submitted. Your account manager will review it shortly.";
      this.requestInsightType = undefined;
      this.requestNotes = "";
      await this.loadMyRequests();
    } catch (error) {
      this.requestError = this.getErrorMessage(error);
    } finally {
      this.submittingRequest = false;
    }
  }

  getErrorMessage(error) {
    return (
      error?.body?.message ||
      error?.message ||
      "AI insights are not available right now."
    );
  }
}
