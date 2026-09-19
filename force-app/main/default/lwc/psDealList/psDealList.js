import { LightningElement, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getMyDeals from "@salesforce/apex/DealRegistrationController.getMyDeals";

export default class PsDealList extends NavigationMixin(LightningElement) {
  @api registerDealPageName = "Register_Deal__c";

  deals = [];
  error;
  loading = true;

  @wire(getMyDeals)
  wiredDeals({ data, error }) {
    this.loading = false;

    if (data) {
      this.deals = data.map((deal) => ({
        ...deal,
        formattedValue: this.formatCurrency(deal.dealValue),
        protectionEndLabel: deal.protectionEndDate || "Not protected",
        badgeVariant: this.getBadgeVariant(deal.status)
      }));
      this.error = undefined;
    } else if (error) {
      this.error = error.body?.message || "Unable to load deals.";
      this.deals = [];
    }
  }

  get hasDeals() {
    return this.deals.length > 0;
  }

  formatCurrency(value) {
    if (value === null || value === undefined) {
      return "$0";
    }

    return new Intl.NumberFormat("en-AU", {
      style: "currency",
      currency: "AUD",
      maximumFractionDigits: 0
    }).format(value);
  }

  getBadgeVariant(status) {
    if (status === "Approved" || status === "Closed Won") {
      return "success";
    }

    if (status === "Rejected" || status === "Closed Lost") {
      return "danger";
    }

    if (status === "Under Review" || status === "Submitted") {
      return "warning";
    }

    return "info";
  }

  handleRegisterDeal() {
    if (!this.registerDealPageName) {
      return;
    }

    this[NavigationMixin.Navigate]({
      type: "comm__namedPage",
      attributes: {
        name: this.registerDealPageName
      }
    });
  }

  handleOpenDeal(event) {
    this.dispatchEvent(
      new CustomEvent("opendeal", {
        detail: { dealId: event.currentTarget.dataset.id }
      })
    );
  }
}
