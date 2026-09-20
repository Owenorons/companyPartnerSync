import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getApprovalQueue from "@salesforce/apex/PartnerRiskApprovalController.getApprovalQueue";
import decideStep from "@salesforce/apex/PartnerRiskApprovalController.decideStep";

const STATUS_OPTIONS = [
  { label: "All Statuses", value: "" },
  { label: "Pending", value: "Pending" },
  { label: "Approved", value: "Approved" },
  { label: "Conditionally Approved", value: "Conditionally Approved" },
  { label: "Rejected", value: "Rejected" },
  { label: "More Information Required", value: "More Information Required" }
];

const DECISION_OPTIONS = [
  { label: "Approved", value: "Approved" },
  { label: "Conditionally Approved", value: "Conditionally Approved" },
  { label: "Rejected", value: "Rejected" },
  { label: "More Information Required", value: "More Information Required" }
];

export default class PsPartnerRiskApprovalWorkspace extends LightningElement {
  steps = [];
  selectedStep;
  selectedStepId;
  selectedStatus = "";
  searchTerm = "";
  error;
  submitting = false;
  submitError;
  decision = "Approved";
  reason = "";
  wiredQueueResult;

  statusOptions = STATUS_OPTIONS;
  decisionOptions = DECISION_OPTIONS;

  @wire(getApprovalQueue)
  wiredApprovalQueue(result) {
    this.wiredQueueResult = result;

    if (result.data) {
      this.steps = result.data.map((step) => this.toQueueViewModel(step));
      this.error = undefined;

      const stillSelected = this.steps.find(
        (step) => step.stepId === this.selectedStepId
      );

      if (stillSelected) {
        this.selectedStep = stillSelected;
      } else if (this.steps.length > 0) {
        this.selectStep(this.steps[0]);
      } else {
        this.selectedStep = undefined;
        this.selectedStepId = undefined;
      }
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load partner risk-approval queue."
      );
      this.steps = [];
      this.selectedStep = undefined;
      this.selectedStepId = undefined;
    }
  }

  get filteredSteps() {
    const term = this.searchTerm.trim().toLowerCase();

    return this.steps
      .filter((step) => {
        const matchesSearch =
          !term ||
          step.partnerName?.toLowerCase().includes(term) ||
          step.dimension?.toLowerCase().includes(term);

        const matchesStatus =
          !this.selectedStatus || step.status === this.selectedStatus;

        return matchesSearch && matchesStatus;
      })
      .map((step) => ({
        ...step,
        rowClass:
          step.stepId === this.selectedStepId ? "queue-row active" : "queue-row"
      }));
  }

  get hasFilteredSteps() {
    return this.filteredSteps.length > 0;
  }

  get showEmptyQueue() {
    return !this.error && !this.hasFilteredSteps;
  }

  get isSubmitDisabled() {
    if (this.submitting || !this.decision) {
      return true;
    }

    return this.decision !== "Approved" && !this.reason.trim();
  }

  handleSearch(event) {
    this.searchTerm = event.target.value || "";
  }

  handleStatus(event) {
    this.selectedStatus = event.detail.value;
  }

  handleSelectStep(event) {
    const step = this.steps.find(
      (candidate) => candidate.stepId === event.currentTarget.dataset.id
    );
    this.selectStep(step);
  }

  handleDecisionChange(event) {
    this.decision = event.detail.value;
  }

  handleReasonChange(event) {
    this.reason = event.target.value || "";
  }

  async handleSubmit() {
    if (this.isSubmitDisabled || !this.selectedStepId) {
      return;
    }

    this.submitting = true;
    this.submitError = undefined;

    try {
      await decideStep({
        request: {
          stepId: this.selectedStepId,
          decision: this.decision,
          reason: this.reason.trim()
        }
      });

      this.reason = "";
      this.decision = "Approved";
      await refreshApex(this.wiredQueueResult);
    } catch (error) {
      this.submitError = this.getErrorMessage(
        error,
        "Unable to process approval-step decision."
      );
    } finally {
      this.submitting = false;
    }
  }

  selectStep(step) {
    this.selectedStep = step;
    this.selectedStepId = step?.stepId;
    this.decision = "Approved";
    this.reason = "";
    this.submitError = undefined;
  }

  toQueueViewModel(step) {
    return {
      ...step,
      partnerName: step.partnerName || "Unknown partner",
      statusClass: this.getStatusClass(step.status),
      decisionOnLabel: this.formatDateTime(step.decisionOn)
    };
  }

  formatDateTime(value) {
    if (!value) {
      return "Not yet decided";
    }

    return new Intl.DateTimeFormat("en-AU", {
      dateStyle: "medium",
      timeStyle: "short"
    }).format(new Date(value));
  }

  getStatusClass(status) {
    if (status === "Approved" || status === "Conditionally Approved") {
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
