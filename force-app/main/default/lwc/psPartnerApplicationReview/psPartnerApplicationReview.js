import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getPendingApplications from "@salesforce/apex/PartnerApplicationController.getPendingApplications";
import getApplicationDetail from "@salesforce/apex/PartnerApplicationController.getApplicationDetail";
import claimApplication from "@salesforce/apex/PartnerApplicationController.claimApplication";
import processDecision from "@salesforce/apex/PartnerApprovalController.processDecision";
import requestProvisioning from "@salesforce/apex/PartnerApprovalController.requestProvisioning";

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
  potentialMatchesAcknowledged = false;
  processingDecision = false;
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
    return this.processingDecision || !this.rejectionReason.trim();
  }

  get isApproveDisabled() {
    return (
      this.processingDecision ||
      (this.selectedApplication?.hasPotentialMatches &&
        !this.potentialMatchesAcknowledged)
    );
  }

  get showNoDecisionPermission() {
    return Boolean(
      this.selectedApplication?.isReviewable &&
      !this.selectedApplication?.canDecide &&
      !this.selectedApplication?.canClaim
    );
  }

  get decisionStateMessage() {
    return this.selectedApplication?.assignedReviewerName
      ? `This application is assigned to ${this.selectedApplication.assignedReviewerName}.`
      : "You do not have permission to review this application.";
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

  async handleClaim() {
    if (!this.selectedApplicationId || this.processingDecision) {
      return;
    }

    this.processingDecision = true;
    this.detailError = undefined;

    try {
      await claimApplication({ applicationId: this.selectedApplicationId });
      await refreshApex(this.wiredQueueResult);
      await this.loadApplication(this.selectedApplicationId);
    } catch (error) {
      this.detailError = this.getErrorMessage(
        error,
        "Unable to start reviewing this application."
      );
    } finally {
      this.processingDecision = false;
    }
  }

  async handleRequestProvisioning() {
    if (!this.selectedApplicationId || this.processingDecision) {
      return;
    }

    this.processingDecision = true;
    this.detailError = undefined;

    try {
      await requestProvisioning({
        applicationId: this.selectedApplicationId
      });
      await this.loadApplication(this.selectedApplicationId);
    } catch (error) {
      this.detailError = this.getErrorMessage(
        error,
        "Unable to request partner access."
      );
    } finally {
      this.processingDecision = false;
    }
  }

  handleReject() {
    this.rejectionReason = "";
    this.showRejectDialog = true;
  }

  handleRejectionReasonChange(event) {
    this.rejectionReason = event.target.value || "";
  }

  handlePotentialMatchesAcknowledgement(event) {
    this.potentialMatchesAcknowledged = event.target.checked;
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
    this.potentialMatchesAcknowledged = false;
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
    if (!this.selectedApplicationId || this.processingDecision) {
      return false;
    }

    this.processingDecision = true;
    this.detailError = undefined;

    try {
      await processDecision({
        request: {
          applicationId: this.selectedApplicationId,
          decision,
          approvalNotes:
            decision === "Approved"
              ? "Approved from partner application review."
              : "",
          confirmPotentialMatches:
            decision === "Approved" && this.potentialMatchesAcknowledged,
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
    } finally {
      this.processingDecision = false;
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
