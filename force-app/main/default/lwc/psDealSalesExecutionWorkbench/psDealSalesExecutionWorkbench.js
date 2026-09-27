import { LightningElement, wire } from "lwc";
import getOpportunityPendingLink from "@salesforce/apex/DealOpportunityController.getOpportunityPendingLink";
import getReapprovalRequired from "@salesforce/apex/DealOpportunityController.getReapprovalRequired";
import getOrphanedRelationships from "@salesforce/apex/DealOpportunityController.getOrphanedRelationships";
import getRecentlyClosed from "@salesforce/apex/DealOpportunityController.getRecentlyClosed";

const TABS = [
  { name: "pendingLink", label: "Opportunity Pending Link" },
  { name: "reapproval", label: "Reapproval Required" },
  { name: "orphaned", label: "Orphaned Relationships" },
  { name: "recentlyClosed", label: "Recently Closed" }
];

export default class PsDealSalesExecutionWorkbench extends LightningElement {
  activeTab = "pendingLink";

  pendingLink = [];
  reapproval = [];
  orphaned = [];
  recentlyClosed = [];

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

  get isPendingLinkTab() {
    return this.activeTab === "pendingLink";
  }

  get isReapprovalTab() {
    return this.activeTab === "reapproval";
  }

  get isOrphanedTab() {
    return this.activeTab === "orphaned";
  }

  get isRecentlyClosedTab() {
    return this.activeTab === "recentlyClosed";
  }

  handleSelectTab(event) {
    this.activeTab = event.currentTarget.dataset.tab;
  }

  @wire(getOpportunityPendingLink)
  wiredPendingLink(result) {
    this.loading = false;
    if (result.data) {
      this.pendingLink = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load deals pending an opportunity link."
      );
      this.pendingLink = [];
    }
  }

  @wire(getReapprovalRequired)
  wiredReapproval(result) {
    if (result.data) {
      this.reapproval = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load deals requiring reapproval."
      );
      this.reapproval = [];
    }
  }

  @wire(getOrphanedRelationships)
  wiredOrphaned(result) {
    if (result.data) {
      this.orphaned = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load orphaned opportunity relationships."
      );
      this.orphaned = [];
    }
  }

  @wire(getRecentlyClosed)
  wiredRecentlyClosed(result) {
    if (result.data) {
      this.recentlyClosed = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load recently closed deals."
      );
      this.recentlyClosed = [];
    }
  }

  get hasPendingLink() {
    return this.pendingLink.length > 0;
  }

  get hasReapproval() {
    return this.reapproval.length > 0;
  }

  get hasOrphaned() {
    return this.orphaned.length > 0;
  }

  get hasRecentlyClosed() {
    return this.recentlyClosed.length > 0;
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
