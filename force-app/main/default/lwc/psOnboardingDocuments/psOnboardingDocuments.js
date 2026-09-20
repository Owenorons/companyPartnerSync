import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getMyRequirements from "@salesforce/apex/PartnerDocumentController.getMyRequirements";
import submitDocument from "@salesforce/apex/PartnerDocumentController.submitDocument";

export default class PsOnboardingDocuments extends LightningElement {
  acceptedFormats = [".pdf", ".png", ".jpg", ".jpeg", ".docx"];

  requirements = [];
  selectedRequirement;
  selectedRequirementId;
  error;
  submitting = false;
  submitError;
  wiredRequirementsResult;

  @wire(getMyRequirements)
  wiredRequirements(result) {
    this.wiredRequirementsResult = result;

    if (result.data) {
      this.requirements = result.data.map((requirement) =>
        this.toRequirementViewModel(requirement)
      );
      this.error = undefined;

      const stillSelected = this.requirements.find(
        (requirement) =>
          requirement.requirementId === this.selectedRequirementId
      );

      if (stillSelected) {
        this.selectedRequirement = stillSelected;
      } else if (this.requirements.length > 0) {
        this.selectRequirement(this.requirements[0]);
      } else {
        this.selectedRequirement = undefined;
        this.selectedRequirementId = undefined;
      }
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load your document requirements."
      );
      this.requirements = [];
      this.selectedRequirement = undefined;
      this.selectedRequirementId = undefined;
    }
  }

  get hasRequirements() {
    return this.requirements.length > 0;
  }

  get showEmptyState() {
    return !this.error && !this.hasRequirements;
  }

  get requirementRows() {
    return this.requirements.map((requirement) => ({
      ...requirement,
      rowClass:
        requirement.requirementId === this.selectedRequirementId
          ? "queue-row active"
          : "queue-row"
    }));
  }

  handleSelectRequirement(event) {
    const requirement = this.requirements.find(
      (candidate) => candidate.requirementId === event.currentTarget.dataset.id
    );
    this.selectRequirement(requirement);
  }

  async handleUploadFinished(event) {
    const uploadedFiles = event.detail.files;

    if (
      !uploadedFiles ||
      uploadedFiles.length === 0 ||
      !this.selectedRequirementId
    ) {
      return;
    }

    this.submitting = true;
    this.submitError = undefined;

    try {
      await submitDocument({
        request: {
          requirementId: this.selectedRequirementId,
          contentDocumentId: uploadedFiles[0].documentId
        }
      });

      await refreshApex(this.wiredRequirementsResult);
    } catch (error) {
      this.submitError = this.getErrorMessage(
        error,
        "Unable to submit your document."
      );
    } finally {
      this.submitting = false;
    }
  }

  selectRequirement(requirement) {
    this.selectedRequirement = requirement;
    this.selectedRequirementId = requirement?.requirementId;
    this.submitError = undefined;
  }

  toRequirementViewModel(requirement) {
    return {
      ...requirement,
      statusClass: this.getStatusClass(requirement.status),
      dueOnLabel: this.formatDate(requirement.dueOn),
      submittedOnLabel: this.formatDateTime(requirement.submittedOn),
      hasLatestDocument: Boolean(requirement.latestDocumentId),
      canUpload: requirement.latestDocumentStatus !== "Accepted"
    };
  }

  formatDate(value) {
    if (!value) {
      return "No due date";
    }

    return new Intl.DateTimeFormat("en-AU", {
      dateStyle: "medium"
    }).format(new Date(value));
  }

  formatDateTime(value) {
    if (!value) {
      return "Not yet submitted";
    }

    return new Intl.DateTimeFormat("en-AU", {
      dateStyle: "medium",
      timeStyle: "short"
    }).format(new Date(value));
  }

  getStatusClass(status) {
    if (status === "Accepted") {
      return "ps-badge ps-badge-success";
    }

    if (status === "Rejected" || status === "Replacement Required") {
      return "ps-badge ps-badge-danger";
    }

    return "ps-badge ps-badge-warning";
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
