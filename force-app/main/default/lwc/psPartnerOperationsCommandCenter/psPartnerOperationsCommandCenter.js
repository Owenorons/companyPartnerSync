import { api, LightningElement, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getOperationsSummary from "@salesforce/apex/PartnerOperationsCommandCenterController.getOperationsSummary";

export default class PsPartnerOperationsCommandCenter extends NavigationMixin(
  LightningElement
) {
  @api customerSuccessWorkbenchTabName = "Customer_Success_Workbench__c";
  @api financeWorkbenchTabName = "Finance_Workbench__c";
  @api portfolioIntelligenceTabName = "Portfolio_Intelligence__c";

  summary;
  error;
  loading = true;

  @wire(getOperationsSummary)
  wiredSummary({ data, error }) {
    this.loading = false;
    if (data) {
      this.summary = data;
      this.error = undefined;
    } else if (error) {
      this.error = this.getErrorMessage(
        error,
        "Unable to load the operations summary."
      );
      this.summary = undefined;
    }
  }

  get hasSummary() {
    return !!this.summary;
  }

  get queues() {
    if (!this.summary) {
      return [];
    }
    return [
      {
        key: "pendingHandoff",
        label: "Pending Handoffs",
        count: this.summary.pendingHandoffCount,
        tabName: this.customerSuccessWorkbenchTabName
      },
      {
        key: "atRiskEngagement",
        label: "At-Risk Engagements",
        count: this.summary.atRiskEngagementCount,
        tabName: this.customerSuccessWorkbenchTabName
      },
      {
        key: "renewalsDue",
        label: "Renewals Due",
        count: this.summary.renewalsDueCount,
        tabName: this.customerSuccessWorkbenchTabName
      },
      {
        key: "partnerConfirmationRequired",
        label: "Renewals Awaiting Partner Confirmation",
        count: this.summary.partnerConfirmationRequiredCount,
        tabName: this.customerSuccessWorkbenchTabName
      },
      {
        key: "openExpansion",
        label: "Open Expansion Opportunities",
        count: this.summary.openExpansionCount,
        tabName: this.customerSuccessWorkbenchTabName
      },
      {
        key: "pendingReassignment",
        label: "Pending Partner Reassignments",
        count: this.summary.pendingReassignmentCount,
        tabName: this.customerSuccessWorkbenchTabName
      },
      {
        key: "openDispute",
        label: "Open Revenue Disputes",
        count: this.summary.openDisputeCount,
        tabName: this.financeWorkbenchTabName
      },
      {
        key: "proposedRecommendation",
        label: "Proposed AI Recommendations",
        count: this.summary.proposedRecommendationCount,
        tabName: this.portfolioIntelligenceTabName
      }
    ];
  }

  handleQueueClick(event) {
    const tabName = event.currentTarget.dataset.tabName;
    if (!tabName) {
      return;
    }
    this[NavigationMixin.Navigate]({
      type: "comm__namedPage",
      attributes: {
        name: tabName
      }
    });
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
