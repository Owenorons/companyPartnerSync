import { api, LightningElement } from "lwc";
import getSummary from "@salesforce/apex/Partner360Controller.getSummary";

export default class PsPartner360 extends LightningElement {
  @api recordId;
  selectedPartnerId;
  summary;
  error;
  loading = false;

  connectedCallback() {
    if (this.recordId) this.load(this.recordId);
  }

  handlePartnerChange(event) {
    this.selectedPartnerId = event.detail.recordId;
    if (this.selectedPartnerId) this.load(this.selectedPartnerId);
    else {
      this.summary = undefined;
      this.error = undefined;
    }
  }

  get pickerValue() {
    return this.selectedPartnerId || this.recordId;
  }

  async load(partnerAccountId) {
    this.loading = true;
    this.error = undefined;
    try {
      this.summary = await getSummary({ partnerAccountId });
    } catch (error) {
      this.summary = undefined;
      this.error = error.body?.message || "Unable to load Partner 360.";
    } finally {
      this.loading = false;
    }
  }

  get hasBlockers() {
    return (this.summary?.blockers || []).length > 0;
  }

  get hasEvents() {
    return (this.summary?.recentEvents || []).length > 0;
  }
}
