import { LightningElement, wire } from "lwc";
import getPendingHandoff from "@salesforce/apex/ImplementationController.getPendingHandoff";
import getReadyToStart from "@salesforce/apex/ImplementationController.getReadyToStart";
import getInProgress from "@salesforce/apex/ImplementationController.getInProgress";
import getAtRiskOrBlocked from "@salesforce/apex/ImplementationController.getAtRiskOrBlocked";
import getAwaitingAcceptance from "@salesforce/apex/ImplementationController.getAwaitingAcceptance";
import getOverdue from "@salesforce/apex/ImplementationController.getOverdue";
import getCompleted from "@salesforce/apex/ImplementationController.getCompleted";

const TABS = [
  { name: "pendingHandoff", label: "Pending Handoff" },
  { name: "readyToStart", label: "Ready to Start" },
  { name: "inProgress", label: "In Progress" },
  { name: "atRiskBlocked", label: "At Risk / Blocked" },
  { name: "awaitingAcceptance", label: "Awaiting Acceptance" },
  { name: "overdue", label: "Overdue" },
  { name: "completed", label: "Completed" }
];

export default class ImplementationWorkbench extends LightningElement {
  activeTab = "pendingHandoff";

  pendingHandoff = [];
  readyToStart = [];
  inProgress = [];
  atRiskBlocked = [];
  awaitingAcceptance = [];
  overdue = [];
  completed = [];

  error;
  loading = true;

  get tabs() {
    return TABS.map((tab) => ({
      ...tab,
      className:
        tab.name === this.activeTab
          ? "tab-button tab-button-active"
          : "tab-button"
    }));
  }

  get isPendingHandoffTab() {
    return this.activeTab === "pendingHandoff";
  }

  get isReadyToStartTab() {
    return this.activeTab === "readyToStart";
  }

  get isInProgressTab() {
    return this.activeTab === "inProgress";
  }

  get isAtRiskBlockedTab() {
    return this.activeTab === "atRiskBlocked";
  }

  get isAwaitingAcceptanceTab() {
    return this.activeTab === "awaitingAcceptance";
  }

  get isOverdueTab() {
    return this.activeTab === "overdue";
  }

  get isCompletedTab() {
    return this.activeTab === "completed";
  }

  handleSelectTab(event) {
    this.activeTab = event.currentTarget.dataset.tab;
  }

  @wire(getPendingHandoff)
  wiredPendingHandoff(result) {
    this.loading = false;
    if (result.data) {
      this.pendingHandoff = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load implementations pending handoff."
      );
      this.pendingHandoff = [];
    }
  }

  @wire(getReadyToStart)
  wiredReadyToStart(result) {
    if (result.data) {
      this.readyToStart = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load implementations ready to start."
      );
      this.readyToStart = [];
    }
  }

  @wire(getInProgress)
  wiredInProgress(result) {
    if (result.data) {
      this.inProgress = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load in-progress implementations."
      );
      this.inProgress = [];
    }
  }

  @wire(getAtRiskOrBlocked)
  wiredAtRiskBlocked(result) {
    if (result.data) {
      this.atRiskBlocked = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load at-risk or blocked implementations."
      );
      this.atRiskBlocked = [];
    }
  }

  @wire(getAwaitingAcceptance)
  wiredAwaitingAcceptance(result) {
    if (result.data) {
      this.awaitingAcceptance = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load implementations awaiting customer acceptance."
      );
      this.awaitingAcceptance = [];
    }
  }

  @wire(getOverdue)
  wiredOverdue(result) {
    if (result.data) {
      this.overdue = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load overdue implementations."
      );
      this.overdue = [];
    }
  }

  @wire(getCompleted)
  wiredCompleted(result) {
    if (result.data) {
      this.completed = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load completed implementations."
      );
      this.completed = [];
    }
  }

  get hasPendingHandoff() {
    return this.pendingHandoff.length > 0;
  }

  get hasReadyToStart() {
    return this.readyToStart.length > 0;
  }

  get hasInProgress() {
    return this.inProgress.length > 0;
  }

  get hasAtRiskBlocked() {
    return this.atRiskBlocked.length > 0;
  }

  get hasAwaitingAcceptance() {
    return this.awaitingAcceptance.length > 0;
  }

  get hasOverdue() {
    return this.overdue.length > 0;
  }

  get hasCompleted() {
    return this.completed.length > 0;
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
