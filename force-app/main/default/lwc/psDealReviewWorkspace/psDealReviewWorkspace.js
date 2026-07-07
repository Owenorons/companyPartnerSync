import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getReviewQueue from "@salesforce/apex/DealReviewController.getReviewQueue";
import getReviewDetail from "@salesforce/apex/DealReviewController.getReviewDetail";
import processDecision from "@salesforce/apex/DealReviewController.processDecision";

const STATUS_OPTIONS = [
  { label: "All Statuses", value: "" },
  { label: "Submitted", value: "Submitted" },
  { label: "Under Review", value: "Under Review" },
  { label: "Approved", value: "Approved" },
  { label: "Rejected", value: "Rejected" }
];

const CONFLICT_OPTIONS = [
  { label: "All Conflicts", value: "" },
  { label: "No Conflict", value: "No Conflict" },
  { label: "Potential Conflict", value: "Potential Conflict" },
  { label: "Conflict Resolved", value: "Conflict Resolved" }
];

export default class PsDealReviewWorkspace extends LightningElement {
  deals = [];
  selectedDeal;
  selectedDealId;
  selectedStatus = "";
  selectedConflict = "";
  searchTerm = "";
  error;
  detailError;
  loadingDetail = false;
  showRejectDialog = false;
  rejectionReason = "";
  wiredQueueResult;

  statusOptions = STATUS_OPTIONS;
  conflictOptions = CONFLICT_OPTIONS;

  @wire(getReviewQueue)
  wiredReviewQueue(result) {
    this.wiredQueueResult = result;

    if (result.data) {
      this.deals = result.data.map((deal) => this.toQueueViewModel(deal));
      this.error = undefined;

      if (!this.selectedDealId && this.deals.length > 0) {
        this.loadDeal(this.deals[0].dealId);
      }
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load deal review queue."
      );
      this.deals = [];
      this.selectedDeal = undefined;
      this.selectedDealId = undefined;
    }
  }

  get filteredDeals() {
    const term = this.searchTerm.trim().toLowerCase();

    return this.deals
      .filter((deal) => {
        const matchesSearch =
          !term ||
          deal.dealNumber?.toLowerCase().includes(term) ||
          deal.customerName?.toLowerCase().includes(term) ||
          deal.partnerName?.toLowerCase().includes(term);

        const matchesStatus =
          !this.selectedStatus || deal.status === this.selectedStatus;
        const matchesConflict =
          !this.selectedConflict ||
          deal.conflictStatus === this.selectedConflict;

        return matchesSearch && matchesStatus && matchesConflict;
      })
      .map((deal) => ({
        ...deal,
        rowClass:
          deal.dealId === this.selectedDealId ? "queue-row active" : "queue-row"
      }));
  }

  get hasFilteredDeals() {
    return this.filteredDeals.length > 0;
  }

  get showEmptyQueue() {
    return !this.error && !this.hasFilteredDeals;
  }

  get isRejectDisabled() {
    return !this.rejectionReason.trim();
  }

  handleSearch(event) {
    this.searchTerm = event.target.value || "";
  }

  handleStatus(event) {
    this.selectedStatus = event.detail.value;
  }

  handleConflict(event) {
    this.selectedConflict = event.detail.value;
  }

  handleSelectDeal(event) {
    this.loadDeal(event.currentTarget.dataset.id);
  }

  async handleApprove() {
    await this.submitDecision("Approved");
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

  async loadDeal(dealId) {
    if (!dealId) {
      return;
    }

    this.selectedDealId = dealId;
    this.loadingDetail = true;
    this.detailError = undefined;

    try {
      const detail = await getReviewDetail({ dealId });
      this.selectedDeal = this.toDetailViewModel(detail);
    } catch (error) {
      this.detailError = this.getErrorMessage(
        error,
        "Unable to load deal detail."
      );
      this.selectedDeal = undefined;
    } finally {
      this.loadingDetail = false;
    }
  }

  async submitDecision(decision, extraFields = {}) {
    if (!this.selectedDealId) {
      return false;
    }

    try {
      await processDecision({
        request: {
          dealId: this.selectedDealId,
          decision,
          approvalNotes:
            decision === "Approved"
              ? "Approved from deal review workspace."
              : "",
          ...extraFields
        }
      });

      await refreshApex(this.wiredQueueResult);
      await this.loadDeal(this.selectedDealId);
      return true;
    } catch (error) {
      this.detailError = this.getErrorMessage(
        error,
        "Unable to process deal decision."
      );
      return false;
    }
  }

  toQueueViewModel(deal) {
    return {
      ...deal,
      customerName: deal.customerName || "Unknown customer",
      partnerName: deal.partnerName || "Unknown partner",
      formattedValue: this.formatCurrency(deal.estimatedRevenue),
      statusClass: this.getStatusClass(deal.status),
      conflictClass: this.getConflictClass(deal.conflictStatus),
      protectionEndLabel: this.formatDate(deal.protectionEndDate),
      createdDateLabel: this.formatDateTime(deal.submittedOn)
    };
  }

  toDetailViewModel(deal = {}) {
    return {
      ...this.toQueueViewModel(deal),
      stage: deal.implementationTimeline || "Review",
      notes: deal.notes || "No notes provided.",
      aiRiskScore: this.getRiskScore(deal),
      aiSummary: this.getRiskSummary(deal),
      aiRecommendation: this.getRecommendation(deal)
    };
  }

  getRiskScore(deal) {
    if (deal.conflictStatus === "Potential Conflict") {
      return 82;
    }

    if (deal.status === "Rejected") {
      return 74;
    }

    return 28;
  }

  getRiskSummary(deal) {
    if (deal.conflictStatus === "Potential Conflict") {
      return "Potential customer or account overlap requires reviewer attention.";
    }

    return "No material conflict signals are present in the current review data.";
  }

  getRecommendation(deal) {
    if (deal.conflictStatus === "Potential Conflict") {
      return "Review related registrations before approving protection.";
    }

    return "Proceed based on qualification, partner fit, and submitted evidence.";
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

  formatDateTime(value) {
    if (!value) {
      return "Not submitted";
    }

    return new Intl.DateTimeFormat("en-AU", {
      dateStyle: "medium",
      timeStyle: "short"
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

  getConflictClass(conflictStatus) {
    if (
      conflictStatus === "No Conflict" ||
      conflictStatus === "Conflict Resolved"
    ) {
      return "ps-badge ps-badge-success";
    }

    if (conflictStatus === "Potential Conflict") {
      return "ps-badge ps-badge-danger";
    }

    return "ps-badge ps-badge-info";
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
