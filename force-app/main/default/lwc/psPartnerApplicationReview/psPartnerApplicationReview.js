import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getPendingApplications from "@salesforce/apex/PartnerApplicationController.getPendingApplications";
import getApplicationDetail from "@salesforce/apex/PartnerApplicationController.getApplicationDetail";
import processDecision from "@salesforce/apex/PartnerApprovalController.processDecision";

export default class PsPartnerApplicationReview extends LightningElement {
  applications = [];
  selectedApplication;
  selectedApplicationId;
  searchTerm = "";
  error;
  detailError;
  loadingDetail = false;
  showRejectDialog = false;
  rejectionReason = "";
  wiredQueueResult;

  @wire(getPendingApplications)
  wiredApplications(result) {
    this.wiredQueueResult = result;

    if (result.data) {
      this.applications = result.data;
      this.error = undefined;

      if (!this.selectedApplicationId && this.applications.length > 0) {
        this.loadApplication(this.applications[0].applicationId);
      }
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load pending applications."
      );
      this.applications = [];
      this.selectedApplication = undefined;
      this.selectedApplicationId = undefined;
    }
  }

  get filteredApplications() {
    const term = this.searchTerm.trim().toLowerCase();

    return this.applications
      .filter(
        (application) =>
          !term || application.companyName?.toLowerCase().includes(term)
      )
      .map((application) => ({
        ...application,
        submittedLabel: this.formatDateTime(application.submittedOn),
        tierChipClass: this.getTierChipClass(application.requestedTier),
        rowClass:
          application.applicationId === this.selectedApplicationId
            ? "queue-row active"
            : "queue-row"
      }));
  }

  get hasFilteredApplications() {
    return this.filteredApplications.length > 0;
  }

  get showEmptyQueue() {
    return !this.error && !this.hasFilteredApplications;
  }

  get isRejectDisabled() {
    return !this.rejectionReason.trim();
  }

  get showNoDecisionPermission() {
    return Boolean(
      this.selectedApplication?.isReviewable &&
      !this.selectedApplication?.canDecide
    );
  }

  handleSearch(event) {
    this.searchTerm = event.target.value || "";
  }

  handleSelectApplication(event) {
    this.loadApplication(event.currentTarget.dataset.id);
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

  async loadApplication(applicationId) {
    if (!applicationId) {
      return;
    }

    this.selectedApplicationId = applicationId;
    this.loadingDetail = true;
    this.detailError = undefined;

    try {
      const detail = await getApplicationDetail({ applicationId });
      this.selectedApplication = this.toDetailViewModel(detail);
    } catch (error) {
      this.detailError = this.getErrorMessage(
        error,
        "Unable to load application detail."
      );
      this.selectedApplication = undefined;
    } finally {
      this.loadingDetail = false;
    }
  }

  async submitDecision(decision, extraFields = {}) {
    if (!this.selectedApplicationId) {
      return false;
    }

    try {
      await processDecision({
        request: {
          applicationId: this.selectedApplicationId,
          decision,
          approvalNotes:
            decision === "Approved"
              ? "Approved from partner application review."
              : "",
          ...extraFields
        }
      });

      await refreshApex(this.wiredQueueResult);
      await this.loadApplication(this.selectedApplicationId);
      return true;
    } catch (error) {
      this.detailError = this.getErrorMessage(
        error,
        "Unable to process application decision."
      );
      return false;
    }
  }

  toDetailViewModel(detail) {
    return {
      ...detail,
      tierChipClass: this.getTierChipClass(detail.requestedTier),
      isStamped: detail.status === "Approved" || detail.status === "Rejected",
      stampClass: detail.status === "Approved" ? "stamp" : "stamp bad"
    };
  }

  getTierChipClass(tier) {
    return `tier-chip tier-${(tier || "").toLowerCase()}`;
  }

  formatDateTime(value) {
    if (!value) {
      return "Not set";
    }

    return new Intl.DateTimeFormat("en-AU", {
      dateStyle: "medium",
      timeStyle: "short"
    }).format(new Date(value));
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
