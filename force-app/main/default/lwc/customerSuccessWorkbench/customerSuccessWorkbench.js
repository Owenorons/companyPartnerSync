import { LightningElement, wire } from "lwc";
import getPendingHandoffs from "@salesforce/apex/CustomerSuccessController.getPendingHandoffs";
import getAtRiskEngagements from "@salesforce/apex/CustomerSuccessController.getAtRiskEngagements";
import getRenewalsDue from "@salesforce/apex/CustomerSuccessController.getRenewalsDue";
import getPartnerConfirmationRequired from "@salesforce/apex/CustomerSuccessController.getPartnerConfirmationRequired";
import getExpansionOpportunities from "@salesforce/apex/CustomerSuccessController.getExpansionOpportunities";
import getPendingReassignments from "@salesforce/apex/CustomerSuccessController.getPendingReassignments";
import getChurnedEngagements from "@salesforce/apex/CustomerSuccessController.getChurnedEngagements";

const TABS = [
  { name: "pendingHandoffs", label: "Pending Handoff" },
  { name: "atRisk", label: "At Risk / Critical" },
  { name: "renewalsDue", label: "Renewals Due" },
  { name: "partnerConfirmation", label: "Partner Confirmation Required" },
  { name: "expansionOpportunities", label: "Expansion Opportunities" },
  { name: "partnerReassignment", label: "Partner Reassignment" },
  { name: "churn", label: "Churn" }
];

export default class CustomerSuccessWorkbench extends LightningElement {
  activeTab = "pendingHandoffs";

  pendingHandoffs = [];
  atRisk = [];
  renewalsDue = [];
  partnerConfirmation = [];
  expansionOpportunities = [];
  partnerReassignment = [];
  churn = [];

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

  get isPendingHandoffsTab() {
    return this.activeTab === "pendingHandoffs";
  }

  get isAtRiskTab() {
    return this.activeTab === "atRisk";
  }

  get isRenewalsDueTab() {
    return this.activeTab === "renewalsDue";
  }

  get isPartnerConfirmationTab() {
    return this.activeTab === "partnerConfirmation";
  }

  get isExpansionOpportunitiesTab() {
    return this.activeTab === "expansionOpportunities";
  }

  get isPartnerReassignmentTab() {
    return this.activeTab === "partnerReassignment";
  }

  get isChurnTab() {
    return this.activeTab === "churn";
  }

  handleSelectTab(event) {
    this.activeTab = event.currentTarget.dataset.tab;
  }

  @wire(getPendingHandoffs)
  wiredPendingHandoffs(result) {
    this.loading = false;
    if (result.data) {
      this.pendingHandoffs = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load pending handoffs."
      );
      this.pendingHandoffs = [];
    }
  }

  @wire(getAtRiskEngagements)
  wiredAtRisk(result) {
    if (result.data) {
      this.atRisk = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load at-risk engagements."
      );
      this.atRisk = [];
    }
  }

  @wire(getRenewalsDue)
  wiredRenewalsDue(result) {
    if (result.data) {
      this.renewalsDue = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load renewals due."
      );
      this.renewalsDue = [];
    }
  }

  @wire(getPartnerConfirmationRequired)
  wiredPartnerConfirmation(result) {
    if (result.data) {
      this.partnerConfirmation = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load renewals awaiting partner confirmation."
      );
      this.partnerConfirmation = [];
    }
  }

  @wire(getExpansionOpportunities)
  wiredExpansionOpportunities(result) {
    if (result.data) {
      this.expansionOpportunities = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load expansion opportunities."
      );
      this.expansionOpportunities = [];
    }
  }

  @wire(getPendingReassignments)
  wiredPartnerReassignment(result) {
    if (result.data) {
      this.partnerReassignment = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load pending partner reassignments."
      );
      this.partnerReassignment = [];
    }
  }

  @wire(getChurnedEngagements)
  wiredChurn(result) {
    if (result.data) {
      this.churn = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load churned engagements."
      );
      this.churn = [];
    }
  }

  get hasPendingHandoffs() {
    return this.pendingHandoffs.length > 0;
  }

  get hasAtRisk() {
    return this.atRisk.length > 0;
  }

  get hasRenewalsDue() {
    return this.renewalsDue.length > 0;
  }

  get hasPartnerConfirmation() {
    return this.partnerConfirmation.length > 0;
  }

  get hasExpansionOpportunities() {
    return this.expansionOpportunities.length > 0;
  }

  get hasPartnerReassignment() {
    return this.partnerReassignment.length > 0;
  }

  get hasChurn() {
    return this.churn.length > 0;
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
