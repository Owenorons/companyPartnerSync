import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getAllSnapshots from "@salesforce/apex/PortfolioIntelligenceController.getAllSnapshots";
import getProposedRecommendations from "@salesforce/apex/PortfolioIntelligenceController.getProposedRecommendations";
import executeRecommendation from "@salesforce/apex/PortfolioIntelligenceController.executeRecommendation";

export default class PsPortfolioIntelligencePanel extends LightningElement {
  snapshots = [];
  recommendations = [];
  error;
  loading = true;
  wiredRecommendationsResult;

  @wire(getAllSnapshots)
  wiredSnapshots(result) {
    this.loading = false;
    if (result.data) {
      this.snapshots = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load portfolio snapshots."
      );
      this.snapshots = [];
    }
  }

  @wire(getProposedRecommendations)
  wiredRecommendations(result) {
    this.wiredRecommendationsResult = result;
    if (result.data) {
      this.recommendations = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load proposed recommendations."
      );
      this.recommendations = [];
    }
  }

  get hasSnapshots() {
    return this.snapshots.length > 0;
  }

  get hasRecommendations() {
    return this.recommendations.length > 0;
  }

  async handleExecuteRecommendation(event) {
    const recommendationId = event.currentTarget.dataset.id;
    try {
      await executeRecommendation({ recommendationId, reason: null });
      await refreshApex(this.wiredRecommendationsResult);
      this.error = undefined;
    } catch (error) {
      this.error = this.getErrorMessage(
        error,
        "Unable to execute the recommendation."
      );
    }
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
