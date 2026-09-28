import { LightningElement, api, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getRevenueSummaries from "@salesforce/apex/RevenueController.getRevenueSummaries";
import getIncentiveSummaries from "@salesforce/apex/RevenueController.getIncentiveSummaries";
import submitClaim from "@salesforce/apex/RevenueController.submitClaim";
import openDispute from "@salesforce/apex/RevenueController.openDispute";

export default class PartnerRevenueWorkspace extends LightningElement {
  @api recordId;

  revenues = [];
  incentives = [];
  error;
  loading = true;
  wiredIncentivesResult;

  @wire(getRevenueSummaries, { dealId: "$recordId" })
  wiredRevenues(result) {
    this.loading = false;
    if (result.data) {
      this.revenues = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load the revenue summary."
      );
      this.revenues = [];
    }
  }

  @wire(getIncentiveSummaries, { dealId: "$recordId" })
  wiredIncentives(result) {
    this.wiredIncentivesResult = result;
    if (result.data) {
      this.incentives = result.data.map((row) => ({
        ...row,
        canSubmitClaim: row.status === "Claim Required"
      }));
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load the incentive summary."
      );
      this.incentives = [];
    }
  }

  get hasRevenues() {
    return this.revenues.length > 0;
  }

  get hasIncentives() {
    return this.incentives.length > 0;
  }

  async handleSubmitClaim(event) {
    const incentiveId = event.currentTarget.dataset.id;

    try {
      await submitClaim({
        command: {
          incentiveId
        }
      });
      await refreshApex(this.wiredIncentivesResult);
    } catch (error) {
      this.error = this.getErrorMessage(
        error,
        "Unable to submit the incentive claim."
      );
    }
  }

  async handleOpenDispute(event) {
    const revenueId = event.currentTarget.dataset.id;

    try {
      await openDispute({
        command: {
          dealId: this.recordId,
          revenueId,
          disputeType: "Missing Revenue",
          description: "Raised from the partner revenue workspace."
        }
      });
      this.error = undefined;
    } catch (error) {
      this.error = this.getErrorMessage(
        error,
        "Unable to open the revenue dispute."
      );
    }
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
