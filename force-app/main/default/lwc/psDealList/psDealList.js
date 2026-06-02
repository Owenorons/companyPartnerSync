import { LightningElement, wire } from "lwc";
import getMyDeals from "@salesforce/apex/DealRegistrationController.getMyDeals";

export default class PsDealList extends LightningElement {
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
        badgeClass: this.getBadgeClass(deal.status)
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

  getBadgeClass(status) {
    if (status === "Approved" || status === "Closed Won") {
      return "badge badge-success";
    }

    if (status === "Rejected" || status === "Closed Lost") {
      return "badge badge-danger";
    }

    if (status === "Under Review" || status === "Submitted") {
      return "badge badge-warning";
    }

    return "badge badge-info";
  }

  handleRegisterDeal() {
    this.dispatchEvent(new CustomEvent("newdeal"));
  }

  handleOpenDeal(event) {
    this.dispatchEvent(
      new CustomEvent("opendeal", {
        detail: { dealId: event.currentTarget.dataset.id }
      })
    );
  }
}
