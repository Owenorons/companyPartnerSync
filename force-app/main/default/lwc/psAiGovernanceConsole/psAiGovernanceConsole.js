import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getPendingReview from "@salesforce/apex/AIInsightController.getPendingReview";
import reviewInsight from "@salesforce/apex/AIInsightController.reviewInsight";
import getInsightTypes from "@salesforce/apex/AIInsightController.getInsightTypes";
import enqueueInsight from "@salesforce/apex/AIInsightController.enqueueInsight";
import getPendingRequests from "@salesforce/apex/AIInsightController.getPendingRequests";
import actionRequest from "@salesforce/apex/AIInsightController.actionRequest";
import dismissRequest from "@salesforce/apex/AIInsightController.dismissRequest";

const POLL_INTERVAL_MS = 2000;
const MAX_POLL_ATTEMPTS = 6;

const PARTNER_ACCOUNT_FILTER = {
  criteria: [{ fieldPath: "Is_Partner__c", operator: "eq", value: true }]
};

export default class PsAiGovernanceConsole extends LightningElement {
  insights = [];
  error;
  loading = true;
  decidingId;
  wiredResult;

  partnerAccountFilter = PARTNER_ACCOUNT_FILTER;
  insightTypeOptions = [];
  selectedPartnerAccountId;
  selectedInsightType;
  generateContext = "";
  generating = false;
  generateError;
  generateStatusMessage;

  requests = [];
  requestsWiredResult;
  requestsError;
  requestActionId;

  @wire(getPendingReview)
  wiredInsights(result) {
    this.wiredResult = result;
    this.loading = false;
    if (result.data) {
      this.insights = result.data.map((row) => ({ ...row }));
      this.error = undefined;
    } else if (result.error) {
      this.error = this.message(result.error);
    }
  }

  @wire(getInsightTypes)
  wiredInsightTypes({ data }) {
    if (data) {
      this.insightTypeOptions = data.map((type) => ({
        label: type.label,
        value: type.developerName
      }));
    }
  }

  @wire(getPendingRequests)
  wiredRequests(result) {
    this.requestsWiredResult = result;
    if (result.data) {
      this.requests = result.data.map((row) => ({ ...row }));
      this.requestsError = undefined;
    } else if (result.error) {
      this.requestsError = this.message(result.error);
    }
  }

  get hasInsights() {
    return this.insights.length > 0;
  }

  get hasRequests() {
    return this.requests.length > 0;
  }

  get isGenerateDisabled() {
    return (
      this.generating ||
      !this.selectedPartnerAccountId ||
      !this.selectedInsightType
    );
  }

  get selectedInsightTypeLabel() {
    const match = this.insightTypeOptions.find(
      (option) => option.value === this.selectedInsightType
    );
    return match ? match.label : undefined;
  }

  handlePartnerChange(event) {
    this.selectedPartnerAccountId = event.detail.recordId;
  }

  handleInsightTypeChange(event) {
    this.selectedInsightType = event.detail.value;
  }

  handleContextChange(event) {
    this.generateContext = event.target.value || "";
  }

  async handleGenerate() {
    if (this.isGenerateDisabled) {
      return;
    }

    this.generating = true;
    this.generateError = undefined;
    this.generateStatusMessage = "Generating… this can take a few seconds.";

    const partnerAccountId = this.selectedPartnerAccountId;
    const insightTypeLabel = this.selectedInsightTypeLabel;
    const submittedAt = new Date();

    try {
      await enqueueInsight({
        request: {
          partnerAccountId,
          insightType: this.selectedInsightType,
          contextData: this.generateContext
            ? { notes: this.generateContext }
            : null
        }
      });

      const found = await this.pollForNewInsight(
        partnerAccountId,
        insightTypeLabel,
        submittedAt
      );
      this.generateStatusMessage = found
        ? "Insight generated — see it in the list below."
        : "Still generating — refresh in a moment to check.";
    } catch (error) {
      this.generateError = this.message(error);
      this.generateStatusMessage = undefined;
    } finally {
      this.generating = false;
    }
  }

  async pollForNewInsight(partnerAccountId, insightTypeLabel, submittedAt) {
    for (let attempt = 0; attempt < MAX_POLL_ATTEMPTS; attempt++) {
      // Sequential, deliberately-paced polling: each attempt must wait for
      // the previous one before checking again.
      // eslint-disable-next-line no-await-in-loop
      await this.wait(POLL_INTERVAL_MS);
      // eslint-disable-next-line no-await-in-loop
      await refreshApex(this.wiredResult);

      const match = this.insights.find(
        (insight) =>
          insight.partnerAccountId === partnerAccountId &&
          insight.insightType === insightTypeLabel &&
          new Date(insight.generatedOn) >= submittedAt
      );

      if (match) {
        return true;
      }
    }

    return false;
  }

  wait(milliseconds) {
    return new Promise((resolve) => {
      // eslint-disable-next-line @lwc/lwc/no-async-operation
      setTimeout(resolve, milliseconds);
    });
  }

  handleRecommendation(event) {
    const id = event.target.dataset.id;
    this.insights = this.insights.map((row) => {
      return row.insightId === id
        ? { ...row, recommendation: event.detail.value }
        : row;
    });
  }

  async handleDecision(event) {
    const insightId = event.currentTarget.dataset.id;
    const decision = event.currentTarget.dataset.decision;
    const row = this.insights.find((item) => item.insightId === insightId);
    if (!row || this.decidingId) return;
    this.decidingId = insightId;
    this.error = undefined;
    try {
      await reviewInsight({
        insightId,
        decision,
        recommendation: row.recommendation
      });
      await refreshApex(this.wiredResult);
    } catch (error) {
      this.error = this.message(error);
    } finally {
      this.decidingId = undefined;
    }
  }

  async handleActionRequest(event) {
    const requestId = event.currentTarget.dataset.id;
    if (this.requestActionId) {
      return;
    }
    this.requestActionId = requestId;
    this.requestsError = undefined;
    try {
      const actioned = await actionRequest({ requestId });
      // Pre-fill the generate form so the reviewer can adjust and submit;
      // actioning only records the request was picked up, it doesn't
      // generate anything by itself.
      this.selectedPartnerAccountId = actioned.partnerAccountId;
      this.selectedInsightType = actioned.insightType;
      this.generateContext = actioned.notes || "";
      await refreshApex(this.requestsWiredResult);
    } catch (error) {
      this.requestsError = this.message(error);
    } finally {
      this.requestActionId = undefined;
    }
  }

  async handleDismissRequest(event) {
    const requestId = event.currentTarget.dataset.id;
    if (this.requestActionId) {
      return;
    }
    this.requestActionId = requestId;
    this.requestsError = undefined;
    try {
      await dismissRequest({ requestId });
      await refreshApex(this.requestsWiredResult);
    } catch (error) {
      this.requestsError = this.message(error);
    } finally {
      this.requestActionId = undefined;
    }
  }

  message(error) {
    return (
      error?.body?.message || error?.message || "Unable to review AI insights."
    );
  }
}
