import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getMyPendingSteps from "@salesforce/apex/DealReviewStepController.getMyPendingSteps";
import getStepDetail from "@salesforce/apex/DealReviewStepController.getStepDetail";
import decide from "@salesforce/apex/DealReviewStepController.decide";

const ACTIONS_BY_STATUS = {
  Ready: ["Start", "Recuse", "Waive", "Escalate", "Cancel"],
  "In Progress": [
    "Complete",
    "Request Info",
    "Recuse",
    "Waive",
    "Escalate",
    "Cancel"
  ],
  "Waiting for Information": [
    "Resume",
    "Recuse",
    "Waive",
    "Escalate",
    "Cancel"
  ],
  Escalated: ["Start", "Recuse", "Waive", "Cancel"],
  "Routing Failed": []
};

const ACTION_LABELS = {
  Start: "Start",
  Complete: "Complete",
  "Request Info": "Request Info",
  Resume: "Resume",
  Recuse: "Recuse",
  Waive: "Waive",
  Escalate: "Escalate",
  Cancel: "Cancel",
  Reassign: "Reassign"
};

const REASON_ACTIONS = new Set(["Recuse", "Waive"]);

export default class PsDealReviewStepWorkspace extends LightningElement {
  steps = [];
  selectedStep;
  selectedReviewId;
  error;
  detailError;
  loadingDetail = false;
  wiredStepsResult;

  showActionDialog = false;
  pendingAction;
  actionReason = "";
  actionOutcome = "";
  actionQuestion = "";
  actionAudience = "";
  actionEvidenceRequirement = "";
  actionAssigneeId;
  saving = false;

  userObjectApiName = "User";

  @wire(getMyPendingSteps)
  wiredMyPendingSteps(result) {
    this.wiredStepsResult = result;

    if (result.data) {
      this.steps = result.data.map((step) => this.toQueueViewModel(step));
      this.error = undefined;

      if (!this.selectedReviewId && this.steps.length > 0) {
        this.loadStep(this.steps[0].reviewId);
      }
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load pending deal review steps."
      );
      this.steps = [];
      this.selectedStep = undefined;
      this.selectedReviewId = undefined;
    }
  }

  get hasSteps() {
    return this.steps.length > 0;
  }

  get showEmptyQueue() {
    return !this.error && !this.hasSteps;
  }

  get availableActions() {
    if (!this.selectedStep) {
      return [];
    }

    const actions = [];

    if (this.selectedStep.canDecide) {
      const statusActions = ACTIONS_BY_STATUS[this.selectedStep.status] || [];
      statusActions.forEach((action) => {
        actions.push({ action, label: ACTION_LABELS[action] });
      });
    }

    if (this.selectedStep.canReassign) {
      actions.push({ action: "Reassign", label: ACTION_LABELS.Reassign });
    }

    return actions;
  }

  get hasAvailableActions() {
    return this.availableActions.length > 0;
  }

  get isTerminalStatus() {
    const status = this.selectedStep?.status;
    return (
      status === "Completed" || status === "Waived" || status === "Cancelled"
    );
  }

  get showNoActionsAvailable() {
    return (
      Boolean(this.selectedStep) &&
      !this.hasAvailableActions &&
      !this.isTerminalStatus
    );
  }

  get isDialogReason() {
    return REASON_ACTIONS.has(this.pendingAction);
  }

  get isDialogComplete() {
    return this.pendingAction === "Complete";
  }

  get isDialogRequestInfo() {
    return this.pendingAction === "Request Info";
  }

  get isDialogReassign() {
    return this.pendingAction === "Reassign";
  }

  get dialogTitle() {
    return this.pendingAction
      ? `${ACTION_LABELS[this.pendingAction]} Review Step`
      : "Act on Review Step";
  }

  get isConfirmDisabled() {
    if (this.saving) {
      return true;
    }
    if (this.isDialogReason) {
      return !this.actionReason.trim();
    }
    if (this.isDialogComplete) {
      return !this.actionOutcome.trim();
    }
    if (this.isDialogRequestInfo) {
      return !this.actionQuestion.trim();
    }
    if (this.isDialogReassign) {
      return !this.actionAssigneeId;
    }
    return false;
  }

  handleSelectStep(event) {
    this.loadStep(event.currentTarget.dataset.id);
  }

  handleActionClick(event) {
    const action = event.currentTarget.dataset.action;
    if (!action) {
      return;
    }

    if (
      action === "Start" ||
      action === "Resume" ||
      action === "Escalate" ||
      action === "Cancel"
    ) {
      this.submitAction(action);
      return;
    }

    this.openDialog(action);
  }

  handleReasonChange(event) {
    this.actionReason = event.target.value || "";
  }

  handleOutcomeChange(event) {
    this.actionOutcome = event.target.value || "";
  }

  handleQuestionChange(event) {
    this.actionQuestion = event.target.value || "";
  }

  handleAudienceChange(event) {
    this.actionAudience = event.target.value || "";
  }

  handleEvidenceRequirementChange(event) {
    this.actionEvidenceRequirement = event.target.value || "";
  }

  handleAssigneeChange(event) {
    this.actionAssigneeId = event.detail.recordId;
  }

  handleCancelDialog() {
    this.closeDialog();
  }

  async handleConfirmDialog() {
    if (this.isConfirmDisabled) {
      return;
    }

    const extraFields = {};
    if (this.isDialogReason) {
      extraFields.reason = this.actionReason.trim();
    } else if (this.isDialogComplete) {
      extraFields.outcome = this.actionOutcome.trim();
    } else if (this.isDialogRequestInfo) {
      extraFields.question = this.actionQuestion.trim();
      extraFields.audience = this.actionAudience.trim();
      extraFields.evidenceRequirement = this.actionEvidenceRequirement.trim();
    } else if (this.isDialogReassign) {
      extraFields.assigneeId = this.actionAssigneeId;
    }

    const wasSubmitted = await this.submitAction(
      this.pendingAction,
      extraFields
    );

    if (wasSubmitted) {
      this.closeDialog();
    }
  }

  openDialog(action) {
    this.pendingAction = action;
    this.actionReason = "";
    this.actionOutcome = "";
    this.actionQuestion = "";
    this.actionAudience = "";
    this.actionEvidenceRequirement = "";
    this.actionAssigneeId = undefined;
    this.showActionDialog = true;
  }

  closeDialog() {
    this.showActionDialog = false;
    this.pendingAction = undefined;
    this.actionReason = "";
    this.actionOutcome = "";
    this.actionQuestion = "";
    this.actionAudience = "";
    this.actionEvidenceRequirement = "";
    this.actionAssigneeId = undefined;
  }

  async loadStep(reviewId) {
    if (!reviewId) {
      return;
    }

    this.selectedReviewId = reviewId;
    this.loadingDetail = true;
    this.detailError = undefined;

    try {
      const detail = await getStepDetail({ reviewId });
      this.selectedStep = this.toDetailViewModel(detail);
    } catch (error) {
      this.detailError = this.getErrorMessage(
        error,
        "Unable to load deal review step detail."
      );
      this.selectedStep = undefined;
    } finally {
      this.loadingDetail = false;
    }
  }

  async submitAction(action, extraFields = {}) {
    if (!this.selectedReviewId || this.saving) {
      return false;
    }

    this.saving = true;

    try {
      await decide({
        request: {
          reviewId: this.selectedReviewId,
          action,
          expectedVersion: this.selectedStep?.expectedVersion,
          ...extraFields
        }
      });

      await refreshApex(this.wiredStepsResult);
      this.selectedReviewId = undefined;
      this.selectedStep = undefined;

      if (this.steps.length > 0) {
        await this.loadStep(this.steps[0].reviewId);
      }

      return true;
    } catch (error) {
      this.detailError = this.getErrorMessage(
        error,
        "Unable to process the deal review step action."
      );
      return false;
    } finally {
      this.saving = false;
    }
  }

  toQueueViewModel(step) {
    return {
      ...step,
      generatedLabel: this.formatDateTime(step.generatedOn),
      dueLabel: this.formatDateTime(step.dueOn),
      recordUrl: this.toRecordUrl(step.dealId),
      rowClass:
        step.reviewId === this.selectedReviewId
          ? "queue-row active"
          : "queue-row"
    };
  }

  toDetailViewModel(step = {}) {
    return {
      ...step,
      generatedLabel: this.formatDateTime(step.generatedOn),
      dueLabel: this.formatDateTime(step.dueOn),
      startedLabel: this.formatDateTime(step.startedOn),
      completedLabel: this.formatDateTime(step.completedOn),
      escalatedLabel: this.formatDateTime(step.escalatedOn),
      recordUrl: this.toRecordUrl(step.dealId)
    };
  }

  toRecordUrl(dealId) {
    return dealId ? `/lightning/r/${dealId}/view` : null;
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
