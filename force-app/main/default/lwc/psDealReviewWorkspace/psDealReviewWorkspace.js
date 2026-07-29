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
  { label: "None", value: "None" },
  { label: "No Conflict", value: "No Conflict" },
  { label: "Potential Conflict", value: "Potential Conflict" },
  { label: "Confirmed Conflict", value: "Confirmed Conflict" },
  { label: "Resolved", value: "Resolved" },
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

  get showNoDecisionPermission() {
    return Boolean(
      this.selectedDeal?.isReviewable &&
      !this.selectedDeal?.canApprove &&
      !this.selectedDeal?.canReject
    );
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
    const conflicts = (deal.conflicts || []).map((conflict) => ({
      ...conflict,
      formattedValue: this.formatCurrency(conflict.estimatedRevenue),
      protectionEndLabel: this.formatDate(conflict.protectionEndDate)
    }));

    return {
      ...this.toQueueViewModel(deal),
      stage: deal.implementationTimeline || "Review",
      notes: deal.notes || "No notes provided.",
      conflicts,
      conflictCount: conflicts.length,
      hasConflicts: conflicts.length > 0,
      isReviewable:
        deal.status === "Submitted" || deal.status === "Under Review",
      isStamped: deal.status === "Approved" || deal.status === "Rejected",
      stampClass: deal.status === "Approved" ? "stamp" : "stamp bad",
      canApprove: Boolean(deal.canApprove),
      canReject: Boolean(deal.canReject),
      showRejectionReason:
        deal.status === "Rejected" && Boolean(deal.rejectionReason),
      showApprovalNotes: Boolean(deal.approvalNotes),
      showConflictResolutionNotes: Boolean(deal.conflictResolutionNotes),
      riskScore: deal.riskScore ?? 0,
      riskLevel: deal.riskLevel || "Not calculated",
      riskScoreClass: `risk-score ${this.getRiskModifier(deal.riskLevel)}`,
      riskSummaryClass: `slds-var-m-top_medium slds-var-p-around_medium risk-summary ${this.getRiskModifier(
        deal.riskLevel
      )}`,
      riskSummary:
        deal.riskSummary ||
        "Risk has not been calculated for this deal registration.",
      riskRecommendation:
        deal.riskRecommendation ||
        "Review the submitted deal details before making a decision."
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
      conflictStatus === "None" ||
      conflictStatus === "No Conflict" ||
      conflictStatus === "Resolved" ||
      conflictStatus === "Conflict Resolved"
    ) {
      return "ps-badge ps-badge-success";
    }

    if (
      conflictStatus === "Potential Conflict" ||
      conflictStatus === "Confirmed Conflict"
    ) {
      return "ps-badge ps-badge-danger";
    }

    return "ps-badge ps-badge-info";
  }

  getRiskModifier(riskLevel) {
    if (riskLevel === "High") {
      return "risk-high";
    }

    if (riskLevel === "Medium") {
      return "risk-medium";
    }

    if (riskLevel === "Low") {
      return "risk-low";
    }

    return "risk-unknown";
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
