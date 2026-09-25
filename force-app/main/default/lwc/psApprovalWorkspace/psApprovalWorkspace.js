import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getMyPendingSteps from "@salesforce/apex/ApprovalController.getMyPendingSteps";
import getStepDetail from "@salesforce/apex/ApprovalController.getStepDetail";
import decide from "@salesforce/apex/ApprovalController.decide";

const REASON_DECISIONS = new Set(["Rejected", "Returned"]);

export default class PsApprovalWorkspace extends LightningElement {
  steps = [];
  selectedStep;
  selectedApprovalId;
  error;
  detailError;
  loadingDetail = false;
  wiredStepsResult;

  showDecisionDialog = false;
  pendingDecision;
  decisionReason = "";
  conditionType = "";
  conditionDescription = "";
  saving = false;

  @wire(getMyPendingSteps)
  wiredMyPendingSteps(result) {
    this.wiredStepsResult = result;

    if (result.data) {
      this.steps = result.data.map((step) => this.toQueueViewModel(step));
      this.error = undefined;

      if (!this.selectedApprovalId && this.steps.length > 0) {
        this.loadStep(this.steps[0].approvalId);
      }
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load pending approval steps."
      );
      this.steps = [];
      this.selectedStep = undefined;
      this.selectedApprovalId = undefined;
    }
  }

  get hasSteps() {
    return this.steps.length > 0;
  }

  get showEmptyQueue() {
    return !this.error && !this.hasSteps;
  }

  get isDialogReason() {
    return REASON_DECISIONS.has(this.pendingDecision);
  }

  get isDialogCondition() {
    return this.pendingDecision === "Approved with Conditions";
  }

  get dialogTitle() {
    if (this.pendingDecision === "Rejected") {
      return "Reject Step";
    }
    if (this.pendingDecision === "Returned") {
      return "Return Step";
    }
    if (this.pendingDecision === "Approved with Conditions") {
      return "Approve with Conditions";
    }
    return "Decide Step";
  }

  get isConfirmDisabled() {
    if (this.saving) {
      return true;
    }
    if (this.isDialogReason) {
      return !this.decisionReason.trim();
    }
    if (this.isDialogCondition) {
      return !this.conditionType.trim() || !this.conditionDescription.trim();
    }
    return false;
  }

  handleSelectStep(event) {
    this.loadStep(event.currentTarget.dataset.id);
  }

  async handleApprove() {
    await this.submitDecision("Approved");
  }

  handleOpenReject() {
    this.openDialog("Rejected");
  }

  handleOpenReturn() {
    this.openDialog("Returned");
  }

  handleOpenApproveWithConditions() {
    this.openDialog("Approved with Conditions");
  }

  handleReasonChange(event) {
    this.decisionReason = event.target.value || "";
  }

  handleConditionTypeChange(event) {
    this.conditionType = event.target.value || "";
  }

  handleConditionDescriptionChange(event) {
    this.conditionDescription = event.target.value || "";
  }

  handleCancelDialog() {
    this.closeDialog();
  }

  async handleConfirmDialog() {
    if (this.isConfirmDisabled) {
      return;
    }

    const extraFields = this.isDialogReason
      ? { reason: this.decisionReason.trim() }
      : {
          conditionType: this.conditionType.trim(),
          conditionDescription: this.conditionDescription.trim()
        };

    const wasSubmitted = await this.submitDecision(
      this.pendingDecision,
      extraFields
    );

    if (wasSubmitted) {
      this.closeDialog();
    }
  }

  openDialog(decision) {
    this.pendingDecision = decision;
    this.decisionReason = "";
    this.conditionType = "";
    this.conditionDescription = "";
    this.showDecisionDialog = true;
  }

  closeDialog() {
    this.showDecisionDialog = false;
    this.pendingDecision = undefined;
    this.decisionReason = "";
    this.conditionType = "";
    this.conditionDescription = "";
  }

  async loadStep(approvalId) {
    if (!approvalId) {
      return;
    }

    this.selectedApprovalId = approvalId;
    this.loadingDetail = true;
    this.detailError = undefined;

    try {
      const detail = await getStepDetail({ approvalId });
      this.selectedStep = this.toDetailViewModel(detail);
    } catch (error) {
      this.detailError = this.getErrorMessage(
        error,
        "Unable to load approval step detail."
      );
      this.selectedStep = undefined;
    } finally {
      this.loadingDetail = false;
    }
  }

  async submitDecision(decision, extraFields = {}) {
    if (!this.selectedApprovalId || this.saving) {
      return false;
    }

    this.saving = true;

    try {
      await decide({
        request: {
          approvalId: this.selectedApprovalId,
          decision,
          expectedVersion: this.selectedStep?.expectedVersion,
          ...extraFields
        }
      });

      await refreshApex(this.wiredStepsResult);
      this.selectedApprovalId = undefined;
      this.selectedStep = undefined;

      if (this.steps.length > 0) {
        await this.loadStep(this.steps[0].approvalId);
      }

      return true;
    } catch (error) {
      this.detailError = this.getErrorMessage(
        error,
        "Unable to process approval step decision."
      );
      return false;
    } finally {
      this.saving = false;
    }
  }

  toQueueViewModel(step) {
    return {
      ...step,
      formattedValue: this.formatCurrency(step.targetAmount),
      generatedLabel: this.formatDateTime(step.generatedOn),
      recordUrl: this.toRecordUrl(step.targetRecordId),
      rowClass:
        step.approvalId === this.selectedApprovalId
          ? "queue-row active"
          : "queue-row"
    };
  }

  toDetailViewModel(step = {}) {
    return {
      ...step,
      formattedValue: this.formatCurrency(step.targetAmount),
      authorityLimitLabel:
        step.authorityLimit === null || step.authorityLimit === undefined
          ? "No limit"
          : this.formatCurrency(step.authorityLimit),
      generatedLabel: this.formatDateTime(step.generatedOn),
      decisionOnLabel: this.formatDateTime(step.decisionOn),
      recordUrl: this.toRecordUrl(step.targetRecordId),
      hasDecision: Boolean(step.decision),
      showNoDecisionPermission: step.status === "Pending" && !step.canDecide
    };
  }

  toRecordUrl(targetRecordId) {
    return targetRecordId ? `/lightning/r/${targetRecordId}/view` : null;
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("en-AU", {
      style: "currency",
      currency: "AUD",
      maximumFractionDigits: 0
    }).format(Number(value || 0));
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
