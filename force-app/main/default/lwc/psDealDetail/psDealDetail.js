import { LightningElement, wire } from "lwc";
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import getDealDetail from "@salesforce/apex/DealRegistrationController.getDealDetail";

export default class PsDealDetail extends NavigationMixin(LightningElement) {
  dealId;
  detail;
  error;
  loading = false;

  @wire(CurrentPageReference)
  setCurrentPageReference(pageReference) {
    const dealId = pageReference?.state?.dealId;

    if (dealId && dealId !== this.dealId) {
      this.dealId = dealId;
      this.load();
    }
  }

  async load() {
    this.loading = true;
    this.error = undefined;

    try {
      this.detail = await getDealDetail({ dealId: this.dealId });
    } catch (error) {
      this.detail = undefined;
      this.error = error.body?.message || "Unable to load deal detail.";
    } finally {
      this.loading = false;
    }
  }

  get hasDetail() {
    return Boolean(this.detail) && !this.error;
  }

  get hasEvents() {
    return (this.detail?.events || []).length > 0;
  }

  get eventRows() {
    return (this.detail?.events || []).map((event) => ({
      ...event,
      occurredOnLabel: this.formatDateTime(event.occurredOn)
    }));
  }

  get badgeVariant() {
    return this.getBadgeVariant(this.detail?.status);
  }

  get formattedValue() {
    return this.formatCurrency(this.detail?.dealValue);
  }

  get estimatedCloseDateLabel() {
    return this.formatDate(this.detail?.estimatedCloseDate);
  }

  get protectionEndDateLabel() {
    return this.formatDate(this.detail?.protectionEndDate);
  }

  get nextActionDueLabel() {
    return this.formatDateTime(this.detail?.nextActionDue);
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

  formatDate(value) {
    if (!value) {
      return "Not set";
    }

    return new Intl.DateTimeFormat("en-AU", {
      dateStyle: "medium"
    }).format(new Date(value));
  }

  formatDateTime(value) {
    if (!value) {
      return "Not set";
    }

    return new Intl.DateTimeFormat("en-AU", {
      dateStyle: "medium",
      timeStyle: "short"
    }).format(new Date(value));
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
}
