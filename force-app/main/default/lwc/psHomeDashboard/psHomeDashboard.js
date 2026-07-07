import { LightningElement, wire } from "lwc";
import getDashboard from "@salesforce/apex/PartnerPortalController.getDashboard";

export default class PsHomeDashboard extends LightningElement {
  dashboard;
  error;
  loading = true;

  @wire(getDashboard)
  wiredDashboard({ data, error }) {
    this.loading = false;

    if (data) {
      this.dashboard = data;
      this.error = undefined;
    } else if (error) {
      this.error = error.body?.message || "Unable to load dashboard.";
      this.dashboard = undefined;
    }
  }

  get hasAlerts() {
    return this.alerts.length > 0;
  }

  get alerts() {
    return Array.isArray(this.dashboard?.alerts) ? this.dashboard.alerts : [];
  }

  get statusClass() {
    const status = this.dashboard?.partnerStatus;

    if (status === "Active") {
      return "ps-badge ps-badge-success";
    }

    if (status === "Suspended") {
      return "ps-badge ps-badge-danger";
    }

    return "ps-badge ps-badge-info";
  }

  handleNewDeal() {
    this.dispatchEvent(
      new CustomEvent("navigate", { detail: { page: "deals" } })
    );
  }

  handleLeads() {
    this.dispatchEvent(
      new CustomEvent("navigate", { detail: { page: "leads" } })
    );
  }

  handleMdf() {
    this.dispatchEvent(
      new CustomEvent("navigate", { detail: { page: "mdf" } })
    );
  }

  handleContent() {
    this.dispatchEvent(
      new CustomEvent("navigate", { detail: { page: "content" } })
    );
  }
}
