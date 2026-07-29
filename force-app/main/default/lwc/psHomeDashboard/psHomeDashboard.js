import { api, LightningElement, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getDashboard from "@salesforce/apex/PartnerPortalController.getDashboard";

export default class PsHomeDashboard extends NavigationMixin(LightningElement) {
  @api registerDealPageName = "Register_Deal__c";
  @api leadsPageName = "Leads";
  @api mdfPageName = "MDF";
  @api contentHubPageName = "Content-Hub";

  dashboard;
  error;
  loading = true;

  @wire(getDashboard)
  wiredDashboard({ data, error }) {
    this.loading = false;

    if (data) {
      this.dashboard = data;
      this.error = undefined;
    } else if (error) {
      this.error = error.body?.message || "Unable to load dashboard.";
      this.dashboard = undefined;
    }
  }

  get hasAlerts() {
    return this.alerts.length > 0;
  }

  get alerts() {
    return Array.isArray(this.dashboard?.alerts) ? this.dashboard.alerts : [];
  }

  get statusVariant() {
    const status = this.dashboard?.partnerStatus;

    if (status === "Active") {
      return "success";
    }

    if (status === "Suspended") {
      return "danger";
    }

    return "info";
  }

  get tierChipClass() {
    const tier = (this.dashboard?.partnerTier || "").toLowerCase();
    return `tier-chip tier-${tier}`;
  }

  handleNewDeal() {
    this.dispatchEvent(
      new CustomEvent("navigate", { detail: { page: "deals" } })
    );

    this.navigateToPage(this.registerDealPageName);
  }

  handleLeads() {
    this.dispatchEvent(
      new CustomEvent("navigate", { detail: { page: "leads" } })
    );

    this.navigateToPage(this.leadsPageName);
  }

  handleMdf() {
    this.dispatchEvent(
      new CustomEvent("navigate", { detail: { page: "mdf" } })
    );

    this.navigateToPage(this.mdfPageName);
  }

  handleContent() {
    this.dispatchEvent(
      new CustomEvent("navigate", { detail: { page: "content" } })
    );

    this.navigateToPage(this.contentHubPageName);
  }

  navigateToPage(pageName) {
    if (!pageName) {
      return;
    }

    this[NavigationMixin.Navigate]({
      type: "comm__namedPage",
      attributes: {
        name: pageName
      }
    });
  }
}
