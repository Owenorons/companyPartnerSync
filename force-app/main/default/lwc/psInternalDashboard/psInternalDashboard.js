import { api, LightningElement, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getDashboard from "@salesforce/apex/InternalPortalController.getDashboard";

export default class PsInternalDashboard extends NavigationMixin(
  LightningElement
) {
  @api dealReviewTabName = "Deal_Review__c";
  @api mdfReviewTabName = "MDF_Review__c";
  @api notificationsTabName = "Notification_Center__c";
  @api contentAdminTabName = "Content_Admin__c";

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

  handleDealReview() {
    this.navigateToTab(this.dealReviewTabName);
  }

  handleMdfReview() {
    this.navigateToTab(this.mdfReviewTabName);
  }

  handleNotifications() {
    this.navigateToTab(this.notificationsTabName);
  }

  handleContentAdmin() {
    this.navigateToTab(this.contentAdminTabName);
  }

  navigateToTab(apiName) {
    if (!apiName) {
      return;
    }

    this[NavigationMixin.Navigate]({
      type: "standard__navItemPage",
      attributes: {
        apiName
      }
    });
  }
}
