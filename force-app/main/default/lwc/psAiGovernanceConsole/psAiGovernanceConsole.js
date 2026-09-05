import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getPendingReview from "@salesforce/apex/AIInsightController.getPendingReview";
import reviewInsight from "@salesforce/apex/AIInsightController.reviewInsight";

export default class PsAiGovernanceConsole extends LightningElement {
  insights = [];
  error;
  loading = true;
  decidingId;
  wiredResult;

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

  get hasInsights() {
    return this.insights.length > 0;
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

  message(error) {
    return (
      error?.body?.message || error?.message || "Unable to review AI insights."
    );
  }
}
