import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getMyEngagements from "@salesforce/apex/CustomerSuccessController.getMyEngagements";
import getMyRenewals from "@salesforce/apex/CustomerSuccessController.getMyRenewals";
import confirmRenewal from "@salesforce/apex/CustomerSuccessController.confirmRenewal";
import declineRenewal from "@salesforce/apex/CustomerSuccessController.declineRenewal";

export default class PartnerCustomerSuccessWorkspace extends LightningElement {
  engagements = [];
  renewals = [];
  error;
  loading = true;
  wiredRenewalsResult;

  @wire(getMyEngagements)
  wiredEngagements(result) {
    this.loading = false;
    if (result.data) {
      this.engagements = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load your customer success engagements."
      );
      this.engagements = [];
    }
  }

  @wire(getMyRenewals)
  wiredRenewals(result) {
    this.wiredRenewalsResult = result;
    if (result.data) {
      this.renewals = result.data.map((row) => ({
        ...row,
        canRespond: row.status === "Partner Confirmation Required"
      }));
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load your renewals."
      );
      this.renewals = [];
    }
  }

  get hasEngagements() {
    return this.engagements.length > 0;
  }

  get hasRenewals() {
    return this.renewals.length > 0;
  }

  async handleConfirmRenewal(event) {
    await this.respondToRenewal(event, confirmRenewal, "confirm");
  }

  async handleDeclineRenewal(event) {
    await this.respondToRenewal(event, declineRenewal, "decline");
  }

  async respondToRenewal(event, action, verb) {
    const renewalId = event.currentTarget.dataset.id;
    const expectedVersion = Number(event.currentTarget.dataset.version);

    try {
      await action({
        command: { renewalId, expectedVersion }
      });
      await refreshApex(this.wiredRenewalsResult);
      this.error = undefined;
    } catch (error) {
      this.error = this.getErrorMessage(
        error,
        `Unable to ${verb} the renewal.`
      );
    }
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
