import { LightningElement, api } from "lwc";
import getMyRequests from "@salesforce/apex/MDFController.getMyRequests";
import resubmitRequest from "@salesforce/apex/MDFController.resubmitRequest";

export default class PsMdfList extends LightningElement {
  requests = [];
  error;
  loading = true;
  resubmittingId;
  resubmitError;

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
        badgeVariant: this.getBadgeVariant(request.status),
        needsInformation: request.status === "Needs Information",
        isResubmitting: request.requestId === this.resubmittingId
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

  async handleResubmit(event) {
    const requestId = event.currentTarget.dataset.id;

    if (!requestId || this.resubmittingId) {
      return;
    }

    this.resubmittingId = requestId;
    this.resubmitError = undefined;
    this.markResubmitting(requestId);

    try {
      await resubmitRequest({ requestId });
      await this.loadRequests();
    } catch (error) {
      this.resubmitError =
        error.body?.message || "Unable to resubmit MDF request.";
      this.markResubmitting(undefined);
    } finally {
      this.resubmittingId = undefined;
    }
  }

  markResubmitting(requestId) {
    this.requests = this.requests.map((request) => ({
      ...request,
      isResubmitting: request.requestId === requestId
    }));
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

    if (
      status === "Submitted" ||
      status === "Under Review" ||
      status === "Needs Information"
    ) {
      return "warning";
    }

    return "info";
  }
}
