import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getPendingConflicts from "@salesforce/apex/DealConflictCommandController.getPendingConflicts";
import getConflictDetail from "@salesforce/apex/DealConflictCommandController.getConflictDetail";
import executeCommand from "@salesforce/apex/DealConflictCommandController.executeCommand";

const ACTIONS_BY_STATUS = {
  Open: [
    "Assign Conflict",
    "Start Investigation",
    "Confirm Conflict",
    "Mark False Positive",
    "Escalate Conflict"
  ],
  Assigned: [
    "Start Investigation",
    "Confirm Conflict",
    "Mark False Positive",
    "Escalate Conflict"
  ],
  Investigating: [
    "Request Evidence",
    "Confirm Conflict",
    "Resolve Conflict",
    "Waive Conflict",
    "Mark False Positive",
    "Escalate Conflict"
  ],
  "Evidence Requested": ["Submit Evidence"],
  Confirmed: ["Resolve Conflict", "Waive Conflict"],
  Escalated: [
    "Assign Conflict",
    "Start Investigation",
    "Confirm Conflict",
    "Mark False Positive"
  ]
};

const ALWAYS_AVAILABLE_ACTIONS = ["Reanalyse Deal"];

const NO_DIALOG_ACTIONS = new Set([
  "Start Investigation",
  "Request Evidence",
  "Confirm Conflict",
  "Escalate Conflict",
  "Reanalyse Deal"
]);

const REASON_ONLY_ACTIONS = new Set([
  "Resolve Conflict",
  "Mark False Positive"
]);

const ACTION_LABELS = {
  "Assign Conflict": "Assign",
  "Start Investigation": "Start Investigation",
  "Request Evidence": "Request Evidence",
  "Submit Evidence": "Submit Evidence",
  "Confirm Conflict": "Confirm",
  "Resolve Conflict": "Resolve",
  "Waive Conflict": "Waive",
  "Mark False Positive": "Mark False Positive",
  "Escalate Conflict": "Escalate",
  "Reanalyse Deal": "Reanalyse Deal"
};

export default class PsDealConflictWorkbench extends LightningElement {
  conflicts = [];
  selectedConflict;
  selectedConflictId;
  error;
  detailError;
  loadingDetail = false;
  wiredConflictsResult;

  showActionDialog = false;
  pendingAction;
  actionReason = "";
  actionAssigneeId;
  actionReviewedEvidence = "";
  actionWaiverConditions = "";
  actionWaiverExpiresOn;
  saving = false;

  userObjectApiName = "User";

  @wire(getPendingConflicts)
  wiredPendingConflicts(result) {
    this.wiredConflictsResult = result;

    if (result.data) {
      this.conflicts = result.data.map((item) => this.toQueueViewModel(item));
      this.error = undefined;

      if (!this.selectedConflictId && this.conflicts.length > 0) {
        this.loadConflict(this.conflicts[0].conflictId);
      }
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load pending deal conflicts."
      );
      this.conflicts = [];
      this.selectedConflict = undefined;
      this.selectedConflictId = undefined;
    }
  }

  get hasConflicts() {
    return this.conflicts.length > 0;
  }

  get showEmptyQueue() {
    return !this.error && !this.hasConflicts;
  }

  get availableActions() {
    if (!this.selectedConflict) {
      return [];
    }

    const statusActions = ACTIONS_BY_STATUS[this.selectedConflict.status] || [];
    const actions = [...statusActions, ...ALWAYS_AVAILABLE_ACTIONS];

    return actions.map((action) => ({
      action,
      label: ACTION_LABELS[action]
    }));
  }

  get hasAvailableActions() {
    return this.availableActions.length > 0;
  }

  get isDialogReasonOnly() {
    return REASON_ONLY_ACTIONS.has(this.pendingAction);
  }

  get isDialogAssign() {
    return this.pendingAction === "Assign Conflict";
  }

  get isDialogSubmitEvidence() {
    return this.pendingAction === "Submit Evidence";
  }

  get isDialogWaive() {
    return this.pendingAction === "Waive Conflict";
  }

  get dialogTitle() {
    return this.pendingAction
      ? `${ACTION_LABELS[this.pendingAction]} Conflict`
      : "Act on Conflict";
  }

  get isConfirmDisabled() {
    if (this.saving) {
      return true;
    }
    if (this.isDialogReasonOnly) {
      return !this.actionReason.trim();
    }
    if (this.isDialogAssign) {
      return !this.actionAssigneeId;
    }
    if (this.isDialogSubmitEvidence) {
      return !this.actionReviewedEvidence.trim();
    }
    if (this.isDialogWaive) {
      return (
        !this.actionReason.trim() ||
        !this.actionReviewedEvidence.trim() ||
        !this.actionWaiverConditions.trim() ||
        !this.actionWaiverExpiresOn
      );
    }
    return false;
  }

  handleSelectConflict(event) {
    this.loadConflict(event.currentTarget.dataset.id);
  }

  handleActionClick(event) {
    const action = event.currentTarget.dataset.action;
    if (!action) {
      return;
    }

    if (NO_DIALOG_ACTIONS.has(action)) {
      this.submitAction(action);
      return;
    }

    this.openDialog(action);
  }

  handleReasonChange(event) {
    this.actionReason = event.target.value || "";
  }

  handleAssigneeChange(event) {
    this.actionAssigneeId = event.detail.recordId;
  }

  handleReviewedEvidenceChange(event) {
    this.actionReviewedEvidence = event.target.value || "";
  }

  handleWaiverConditionsChange(event) {
    this.actionWaiverConditions = event.target.value || "";
  }

  handleWaiverExpiresOnChange(event) {
    this.actionWaiverExpiresOn = event.target.value || undefined;
  }

  handleCancelDialog() {
    this.closeDialog();
  }

  async handleConfirmDialog() {
    if (this.isConfirmDisabled) {
      return;
    }

    const extraFields = {};
    if (this.isDialogReasonOnly) {
      extraFields.reason = this.actionReason.trim();
    } else if (this.isDialogAssign) {
      extraFields.assigneeId = this.actionAssigneeId;
    } else if (this.isDialogSubmitEvidence) {
      extraFields.reviewedEvidence = this.actionReviewedEvidence.trim();
    } else if (this.isDialogWaive) {
      extraFields.reason = this.actionReason.trim();
      extraFields.reviewedEvidence = this.actionReviewedEvidence.trim();
      extraFields.waiverConditions = this.actionWaiverConditions.trim();
      extraFields.waiverExpiresOn = new Date(
        this.actionWaiverExpiresOn
      ).toISOString();
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
    this.actionAssigneeId = undefined;
    this.actionReviewedEvidence = "";
    this.actionWaiverConditions = "";
    this.actionWaiverExpiresOn = undefined;
    this.showActionDialog = true;
  }

  closeDialog() {
    this.showActionDialog = false;
    this.pendingAction = undefined;
    this.actionReason = "";
    this.actionAssigneeId = undefined;
    this.actionReviewedEvidence = "";
    this.actionWaiverConditions = "";
    this.actionWaiverExpiresOn = undefined;
  }

  async loadConflict(conflictId) {
    if (!conflictId) {
      return;
    }

    this.selectedConflictId = conflictId;
    this.loadingDetail = true;
    this.detailError = undefined;

    try {
      const detail = await getConflictDetail({ conflictId });
      this.selectedConflict = this.toDetailViewModel(detail);
    } catch (error) {
      this.detailError = this.getErrorMessage(
        error,
        "Unable to load deal conflict detail."
      );
      this.selectedConflict = undefined;
    } finally {
      this.loadingDetail = false;
    }
  }

  async submitAction(action, extraFields = {}) {
    if (!this.selectedConflictId || this.saving) {
      return false;
    }

    this.saving = true;

    const request = {
      conflictId: this.selectedConflictId,
      action,
      commandKey: `workbench-${this.selectedConflictId}-${action}-${Date.now()}`,
      expectedVersion: this.selectedConflict?.expectedVersion,
      ...extraFields
    };

    try {
      await executeCommand({ requestJson: JSON.stringify(request) });

      await refreshApex(this.wiredConflictsResult);
      this.selectedConflictId = undefined;
      this.selectedConflict = undefined;

      if (this.conflicts.length > 0) {
        await this.loadConflict(this.conflicts[0].conflictId);
      }

      return true;
    } catch (error) {
      this.detailError = this.getErrorMessage(
        error,
        "Unable to process the conflict action."
      );
      return false;
    } finally {
      this.saving = false;
    }
  }

  toQueueViewModel(item) {
    return {
      ...item,
      detectedLabel: this.formatDateTime(item.detectedOn),
      recordUrl: this.toRecordUrl(item.dealId),
      rowClass:
        item.conflictId === this.selectedConflictId
          ? "queue-row active"
          : "queue-row"
    };
  }

  toDetailViewModel(item = {}) {
    return {
      ...item,
      detectedLabel: this.formatDateTime(item.detectedOn),
      investigationStartedLabel: this.formatDateTime(
        item.investigationStartedOn
      ),
      escalatedLabel: this.formatDateTime(item.escalatedOn),
      slaDueLabel: this.formatDateTime(item.slaDue),
      resolvedLabel: this.formatDateTime(item.resolvedOn),
      waivedLabel: this.formatDateTime(item.waivedOn),
      waiverExpiresLabel: this.formatDateTime(item.waiverExpiresOn),
      recordUrl: this.toRecordUrl(item.dealId),
      matchedRecordUrl: this.toRecordUrl(item.matchedDealId)
    };
  }

  toRecordUrl(recordId) {
    return recordId ? `/lightning/r/${recordId}/view` : null;
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
