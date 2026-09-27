import { LightningElement, api, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getImplementationSummary from "@salesforce/apex/ImplementationController.getImplementationSummary";
import getImplementationDetail from "@salesforce/apex/ImplementationController.getImplementationDetail";
import completeMilestone from "@salesforce/apex/ImplementationController.completeMilestone";

export default class PartnerImplementationWorkspace extends LightningElement {
  @api recordId;

  summary;
  milestones = [];
  evidenceItems = [];
  issues = [];
  acceptances = [];
  error;
  loading = true;

  implementationId;
  wiredDetailResult;

  @wire(getImplementationSummary, { dealId: "$recordId" })
  wiredSummary(result) {
    this.loading = false;
    if (result.data) {
      this.summary = result.data;
      this.implementationId = result.data.implementationId;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load the implementation summary."
      );
      this.summary = undefined;
      this.implementationId = undefined;
    }
  }

  @wire(getImplementationDetail, { implementationId: "$implementationId" })
  wiredDetail(result) {
    this.wiredDetailResult = result;
    if (result.data) {
      this.summary = result.data.summary;
      this.milestones = result.data.milestones.map((row) => ({
        ...row,
        canComplete: row.status === "In Progress"
      }));
      this.evidenceItems = result.data.evidenceItems;
      this.issues = result.data.issues;
      this.acceptances = result.data.acceptances;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load the implementation detail."
      );
    }
  }

  get hasImplementation() {
    return Boolean(this.summary);
  }

  get hasMilestones() {
    return this.milestones.length > 0;
  }

  get hasEvidenceItems() {
    return this.evidenceItems.length > 0;
  }

  get hasIssues() {
    return this.issues.length > 0;
  }

  get hasAcceptances() {
    return this.acceptances.length > 0;
  }

  async handleCompleteMilestone(event) {
    const milestoneId = event.currentTarget.dataset.id;
    const milestone = this.milestones.find(
      (row) => row.milestoneId === milestoneId
    );

    try {
      await completeMilestone({
        command: {
          milestoneId,
          expectedVersion: milestone ? milestone.versionNumber : null
        }
      });
      await refreshApex(this.wiredDetailResult);
    } catch (error) {
      this.error = this.getErrorMessage(
        error,
        "Unable to complete the milestone."
      );
    }
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
