import { LightningElement, api } from "lwc";
import getMyRequests from "@salesforce/apex/MDFController.getMyRequests";

export default class PsMdfList extends LightningElement {
  requests = [];
  error;
  loading = true;

  _refreshToken;
  _connected = false;

  @api
  get refreshToken() {
    return this._refreshToken;
  }

  set refreshToken(value) {
    const changed = this._refreshToken !== value;
    this._refreshToken = value;

    if (changed && this._connected) {
      this.loadRequests();
    }
  }

  connectedCallback() {
    this._connected = true;
    this.loadRequests();
  }

  async loadRequests() {
    this.loading = true;

    try {
      const data = await getMyRequests();

      this.requests = data.map((request) => ({
        ...request,
        requestedLabel: this.formatCurrency(request.requestedAmount),
        approvedLabel: this.formatCurrency(request.approvedAmount),
        badgeVariant: this.getBadgeVariant(request.status)
      }));
      this.error = undefined;
    } catch (error) {
      this.error = error.body?.message || "Unable to load MDF requests.";
      this.requests = [];
    } finally {
      this.loading = false;
    }
  }

  get hasRequests() {
    return this.requests.length > 0;
  }

  formatCurrency(value) {
    if (value === null || value === undefined) {
      return "$0";
    }

    return new Intl.NumberFormat("en-AU", {
      style: "currency",
      currency: "AUD",
      maximumFractionDigits: 0
    }).format(value);
  }

  getBadgeVariant(status) {
    if (status === "Approved" || status === "Reimbursed") {
      return "success";
    }

    if (status === "Rejected") {
      return "danger";
    }

    if (status === "Submitted" || status === "Under Review") {
      return "warning";
    }

    return "info";
  }
}
