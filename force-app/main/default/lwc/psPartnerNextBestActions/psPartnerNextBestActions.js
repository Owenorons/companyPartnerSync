import { LightningElement } from "lwc";
import getMyNextBestActions from "@salesforce/apex/PartnerAIController.getMyNextBestActions";

export default class PsPartnerNextBestActions extends LightningElement {
  actions = [];
  error;
  isLoading = true;

  connectedCallback() {
    this.loadActions();
  }

  async loadActions() {
    this.isLoading = true;
    this.error = undefined;

    try {
      const rows = await getMyNextBestActions();
      this.actions = (rows || []).map((row) => ({
        ...row,
        confidenceLabel: row.confidence
          ? `${Math.round(Number(row.confidence))}%`
          : "Not set"
      }));
    } catch (error) {
      this.error =
        error?.body?.message ||
        error?.message ||
        "Recommendations are not available right now.";
      this.actions = [];
    } finally {
      this.isLoading = false;
    }
  }

  get hasActions() {
    return this.actions.length > 0;
  }
}
