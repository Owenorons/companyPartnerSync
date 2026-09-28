import { LightningElement, wire } from "lwc";
import getUnmatchedRevenue from "@salesforce/apex/RevenueController.getUnmatchedRevenue";
import getAttributionExceptions from "@salesforce/apex/RevenueController.getAttributionExceptions";
import getClaimsUnderReview from "@salesforce/apex/RevenueController.getClaimsUnderReview";
import getPaymentPending from "@salesforce/apex/RevenueController.getPaymentPending";
import getOpenDisputes from "@salesforce/apex/RevenueController.getOpenDisputes";

const TABS = [
  { name: "unmatchedRevenue", label: "Unmatched Revenue" },
  { name: "attributionExceptions", label: "Attribution Exceptions" },
  { name: "claimsUnderReview", label: "Claims Under Review" },
  { name: "paymentPending", label: "Payment Pending" },
  { name: "openDisputes", label: "Open Disputes" }
];

export default class FinanceWorkbench extends LightningElement {
  activeTab = "unmatchedRevenue";

  unmatchedRevenue = [];
  attributionExceptions = [];
  claimsUnderReview = [];
  paymentPending = [];
  openDisputes = [];

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

  get isUnmatchedRevenueTab() {
    return this.activeTab === "unmatchedRevenue";
  }

  get isAttributionExceptionsTab() {
    return this.activeTab === "attributionExceptions";
  }

  get isClaimsUnderReviewTab() {
    return this.activeTab === "claimsUnderReview";
  }

  get isPaymentPendingTab() {
    return this.activeTab === "paymentPending";
  }

  get isOpenDisputesTab() {
    return this.activeTab === "openDisputes";
  }

  handleSelectTab(event) {
    this.activeTab = event.currentTarget.dataset.tab;
  }

  @wire(getUnmatchedRevenue)
  wiredUnmatchedRevenue(result) {
    this.loading = false;
    if (result.data) {
      this.unmatchedRevenue = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load unmatched revenue."
      );
      this.unmatchedRevenue = [];
    }
  }

  @wire(getAttributionExceptions)
  wiredAttributionExceptions(result) {
    if (result.data) {
      this.attributionExceptions = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load attribution exceptions."
      );
      this.attributionExceptions = [];
    }
  }

  @wire(getClaimsUnderReview)
  wiredClaimsUnderReview(result) {
    if (result.data) {
      this.claimsUnderReview = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load claims under review."
      );
      this.claimsUnderReview = [];
    }
  }

  @wire(getPaymentPending)
  wiredPaymentPending(result) {
    if (result.data) {
      this.paymentPending = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load payments pending."
      );
      this.paymentPending = [];
    }
  }

  @wire(getOpenDisputes)
  wiredOpenDisputes(result) {
    if (result.data) {
      this.openDisputes = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load open disputes."
      );
      this.openDisputes = [];
    }
  }

  get hasUnmatchedRevenue() {
    return this.unmatchedRevenue.length > 0;
  }

  get hasAttributionExceptions() {
    return this.attributionExceptions.length > 0;
  }

  get hasClaimsUnderReview() {
    return this.claimsUnderReview.length > 0;
  }

  get hasPaymentPending() {
    return this.paymentPending.length > 0;
  }

  get hasOpenDisputes() {
    return this.openDisputes.length > 0;
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
