import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getReviewQueue from "@salesforce/apex/MDFController.getReviewQueue";
import processDecision from "@salesforce/apex/MDFController.processDecision";

/**
 * Internal reviewer workspace for MDF requests, modeled on
 * c-ps-deal-review-workspace. MDFController has no getReviewDetail — the
 * review queue already returns every field the decision panel needs, so
 * the selected row IS the detail, with no second server round trip.
 */
export default class PsMdfReviewWorkspace extends LightningElement {
  requests = [];
  selectedRequestId;
  searchTerm = "";
  approvedAmountInput;
  error;
  decisionError;
  isSubmitting = false;
  showRejectDialog = false;
  rejectionReason = "";
  wiredQueueResult;

  @wire(getReviewQueue)
  wiredReviewQueue(result) {
    this.wiredQueueResult = result;

    if (result.data) {
      this.requests = result.data.map((request) =>
        this.toRowViewModel(request)
      );
      this.error = undefined;

      const stillPresent = this.requests.some(
        (request) => request.requestId === this.selectedRequestId
      );

      if (!stillPresent) {
        this.selectRequest(this.requests[0]?.requestId);
      }
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load the MDF review queue."
      );
      this.requests = [];
      this.selectedRequestId = undefined;
    }
  }

  get filteredRequests() {
    const term = this.searchTerm.trim().toLowerCase();

    return this.requests
      .filter(
        (request) =>
          !term ||
          request.requestNumber?.toLowerCase().includes(term) ||
          request.partnerName?.toLowerCase().includes(term) ||
          request.campaignName?.toLowerCase().includes(term)
      )
      .map((request) => ({
        ...request,
        rowClass:
          request.requestId === this.selectedRequestId
            ? "queue-row active"
            : "queue-row"
      }));
  }

  get hasFilteredRequests() {
    return this.filteredRequests.length > 0;
  }

  get showEmptyQueue() {
    return !this.error && !this.hasFilteredRequests;
  }

  get selectedRequest() {
    return this.requests.find(
      (request) => request.requestId === this.selectedRequestId
    );
  }

  get isRejectDisabled() {
    return this.isSubmitting || !this.rejectionReason.trim();
  }

  get isApproveDisabled() {
    return this.isSubmitting || !(Number(this.approvedAmountInput) > 0);
  }

  handleSearch(event) {
    this.searchTerm = event.target.value || "";
  }

  handleSelectRequest(event) {
    this.selectRequest(event.currentTarget.dataset.id);
  }

  handleApprovedAmountChange(event) {
    this.approvedAmountInput = event.target.value;
  }

  async handleApprove() {
    if (this.isApproveDisabled) {
      return;
    }

    await this.submitDecision("Approved", {
      approvedAmount: Number(this.approvedAmountInput)
    });
  }

  handleReject() {
    this.rejectionReason = "";
    this.showRejectDialog = true;
  }

  handleRejectionReasonChange(event) {
    this.rejectionReason = event.target.value || "";
  }

  handleCancelReject() {
    this.showRejectDialog = false;
    this.rejectionReason = "";
  }

  async handleConfirmReject() {
    if (this.isRejectDisabled) {
      return;
    }

    const wasSubmitted = await this.submitDecision("Rejected", {
      rejectionReason: this.rejectionReason.trim()
    });

    if (wasSubmitted) {
      this.handleCancelReject();
    }
  }

  selectRequest(requestId) {
    this.selectedRequestId = requestId;
    this.decisionError = undefined;

    const request = this.requests.find((row) => row.requestId === requestId);
    this.approvedAmountInput = request?.requestedAmount ?? null;
  }

  async submitDecision(decision, extraFields = {}) {
    if (!this.selectedRequestId) {
      return false;
    }

    this.isSubmitting = true;
    this.decisionError = undefined;

    try {
      await processDecision({
        request: {
          requestId: this.selectedRequestId,
          decision,
          decisionNotes:
            decision === "Approved"
              ? "Approved from MDF review workspace."
              : "",
          ...extraFields
        }
      });

      await refreshApex(this.wiredQueueResult);
      return true;
    } catch (error) {
      this.decisionError = this.getErrorMessage(
        error,
        "Unable to process MDF decision."
      );
      return false;
    } finally {
      this.isSubmitting = false;
    }
  }

  toRowViewModel(request) {
    return {
      ...request,
      partnerName: request.partnerName || "Unknown partner",
      campaignName: request.campaignName || "Untitled campaign",
      formattedRequested: this.formatCurrency(request.requestedAmount),
      formattedApproved: this.formatCurrency(request.approvedAmount),
      statusClass: this.getStatusClass(request.status),
      stampClass: request.status === "Approved" ? "stamp" : "stamp bad",
      startLabel: this.formatDate(request.startDate),
      endLabel: this.formatDate(request.endDate),
      isReviewable:
        request.status === "Submitted" || request.status === "Under Review"
    };
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("en-AU", {
      style: "currency",
      currency: "AUD",
      maximumFractionDigits: 0
    }).format(Number(value || 0));
  }

  formatDate(value) {
    if (!value) {
      return "Not set";
    }

    return new Intl.DateTimeFormat("en-AU", {
      dateStyle: "medium"
    }).format(new Date(value));
  }

  getStatusClass(status) {
    if (status === "Approved") {
      return "ps-badge ps-badge-success";
    }

    if (status === "Rejected") {
      return "ps-badge ps-badge-danger";
    }

    return "ps-badge ps-badge-warning";
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
