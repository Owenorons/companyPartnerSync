import { api, LightningElement, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getDashboard from "@salesforce/apex/InternalPortalController.getDashboard";
import acknowledgeOperationalAlert from "@salesforce/apex/InternalPortalController.acknowledgeOperationalAlert";
import transitionOperationalAlert from "@salesforce/apex/InternalPortalController.transitionOperationalAlert";

export default class PsInternalDashboard extends NavigationMixin(
  LightningElement
) {
  unifiedWorkColumns = [
    { label: "Domain", fieldName: "domain", type: "text" },
    { label: "Type", fieldName: "workType", type: "text" },
    { label: "Work item", fieldName: "title", type: "text", wrapText: true },
    { label: "Priority", fieldName: "priority", type: "text" },
    { label: "Status", fieldName: "status", type: "text" },
    {
      label: "Due / received",
      fieldName: "dueOn",
      type: "date",
      typeAttributes: { year: "numeric", month: "short", day: "2-digit" }
    },
    {
      type: "button",
      typeAttributes: { label: "Open", name: "open", variant: "base" }
    }
  ];
  onboardingColumns = [
    { label: "Queue", fieldName: "queueType", type: "text" },
    { label: "Work item", fieldName: "title", type: "text", wrapText: true },
    { label: "Priority", fieldName: "priority", type: "text" },
    { label: "Status", fieldName: "status", type: "text" },
    {
      label: "Due",
      fieldName: "dueOn",
      type: "date",
      typeAttributes: { year: "numeric", month: "short", day: "2-digit" }
    },
    {
      type: "button",
      typeAttributes: { label: "Open", name: "open", variant: "base" }
    }
  ];
  complianceColumns = [
    { label: "Issue", fieldName: "category", type: "text" },
    { label: "Evidence", fieldName: "documentType", type: "text" },
    { label: "Severity", fieldName: "severity", type: "text" },
    { label: "Status", fieldName: "status", type: "text" },
    {
      label: "Due / expires",
      fieldName: "dueOn",
      type: "date",
      typeAttributes: { year: "numeric", month: "short", day: "2-digit" }
    },
    {
      label: "Required action",
      fieldName: "message",
      type: "text",
      wrapText: true
    },
    {
      type: "button",
      typeAttributes: { label: "Open", name: "open", variant: "base" }
    }
  ];
  operationalAlertColumns = [
    { label: "Type", fieldName: "alertType", type: "text" },
    { label: "Severity", fieldName: "severity", type: "text" },
    { label: "Status", fieldName: "status", type: "text" },
    { label: "Message", fieldName: "message", type: "text", wrapText: true },
    { label: "Occurrences", fieldName: "occurrenceCount", type: "number" },
    {
      label: "Last detected",
      fieldName: "lastDetectedOn",
      type: "date",
      typeAttributes: {
        year: "numeric",
        month: "short",
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit"
      }
    },
    {
      type: "button",
      typeAttributes: {
        label: "Acknowledge",
        name: "acknowledge",
        variant: "brand",
        disabled: { fieldName: "acknowledgeDisabled" }
      }
    },
    {
      type: "button",
      typeAttributes: {
        label: { fieldName: "transitionLabel" },
        name: "transition",
        variant: "neutral"
      }
    }
  ];
  @api dealReviewTabName = "Deal_Review__c";
  @api mdfReviewTabName = "MDF_Review__c";
  @api notificationsTabName = "Notification_Center__c";
  @api contentAdminTabName = "Content_Admin__c";
  @api partner360TabName = "Partner_360__c";

  dashboard;
  error;
  loading = true;
  wiredDashboardResult;
  alertStatusFilter = "All";
  alertSeverityFilter = "All";
  alertTypeFilter = "All";
  alertDetectedFrom;
  workDomainFilter = "All";
  workPriorityFilter = "All";

  statusOptions = ["All", "Open", "Acknowledged", "Resolved"].map((value) => ({
    label: value,
    value
  }));
  severityOptions = ["All", "Critical", "High", "Medium"].map((value) => ({
    label: value,
    value
  }));

  get workDomainOptions() {
    const domains = new Set(
      (this.dashboard?.unifiedWorkItems || []).map((row) => row.domain)
    );
    return ["All", ...Array.from(domains).sort()].map((value) => ({
      label: value,
      value
    }));
  }

  get workPriorityOptions() {
    return ["All", "Critical", "High", "Medium", "Low"].map((value) => ({
      label: value,
      value
    }));
  }

  get unifiedWorkItems() {
    const rows = Array.isArray(this.dashboard?.unifiedWorkItems)
      ? this.dashboard.unifiedWorkItems
      : [];
    return rows
      .filter(
        (row) =>
          this.workDomainFilter === "All" ||
          row.domain === this.workDomainFilter
      )
      .filter(
        (row) =>
          this.workPriorityFilter === "All" ||
          row.priority === this.workPriorityFilter
      );
  }

  get hasUnifiedWork() {
    return this.unifiedWorkItems.length > 0;
  }

  @wire(getDashboard)
  wiredDashboard(result) {
    this.wiredDashboardResult = result;
    const { data, error } = result;
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

  get onboardingWorkItems() {
    return Array.isArray(this.dashboard?.onboardingWorkItems)
      ? this.dashboard.onboardingWorkItems
      : [];
  }

  get hasOnboardingWork() {
    return this.onboardingWorkItems.length > 0;
  }

  get complianceItems() {
    return Array.isArray(this.dashboard?.complianceItems)
      ? this.dashboard.complianceItems
      : [];
  }

  get hasComplianceItems() {
    return this.complianceItems.length > 0;
  }

  get onboardingCompletionLabel() {
    return new Intl.NumberFormat("en-AU", {
      style: "percent",
      maximumFractionDigits: 0
    }).format(Number(this.dashboard?.onboardingCompletionRate || 0));
  }

  get averageActivationLabel() {
    const days = Number(this.dashboard?.averageActivationDays || 0);
    return `${days.toFixed(days % 1 === 0 ? 0 : 1)} days`;
  }

  get onboardingBottleneckLabel() {
    const stage =
      this.dashboard?.onboardingBottleneckStage || "No active onboarding";
    const count = Number(this.dashboard?.onboardingBottleneckCount || 0);
    return count > 0 ? `${stage} (${count})` : stage;
  }

  get operationalAlerts() {
    const rows = Array.isArray(this.dashboard?.operationalAlerts)
      ? this.dashboard.operationalAlerts
      : [];
    return rows
      .filter(
        (row) =>
          this.alertStatusFilter === "All" ||
          row.status === this.alertStatusFilter
      )
      .filter(
        (row) =>
          this.alertSeverityFilter === "All" ||
          row.severity === this.alertSeverityFilter
      )
      .filter(
        (row) =>
          this.alertTypeFilter === "All" ||
          row.alertType === this.alertTypeFilter
      )
      .filter(
        (row) =>
          !this.alertDetectedFrom ||
          row.lastDetectedOn?.slice(0, 10) >= this.alertDetectedFrom
      )
      .map((row) => ({ ...row, acknowledgeDisabled: !row.canAcknowledge }));
  }

  get alertTypeOptions() {
    const types = new Set(
      (this.dashboard?.operationalAlerts || []).map((row) => row.alertType)
    );
    return ["All", ...Array.from(types).sort()].map((value) => ({
      label: value,
      value
    }));
  }

  get hasOperationalAlerts() {
    return this.operationalAlerts.length > 0;
  }

  async handleOperationalAlertAction(event) {
    const { action, row } = event.detail;
    try {
      let message;
      if (action.name === "acknowledge") {
        await acknowledgeOperationalAlert({ alertId: row.recordId });
        message = "The operational alert was acknowledged.";
      } else if (action.name === "transition") {
        const actionName = row.status === "Resolved" ? "reopen" : "resolve";
        await transitionOperationalAlert({ alertId: row.recordId, actionName });
        message = `The operational alert was ${actionName === "reopen" ? "reopened" : "resolved"}.`;
      } else return;
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Alert updated",
          message,
          variant: "success"
        })
      );
      await refreshApex(this.wiredDashboardResult);
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Unable to acknowledge alert",
          message:
            error.body?.message ||
            "The operational alert could not be acknowledged.",
          variant: "error"
        })
      );
    }
  }

  handleAlertFilter(event) {
    const propertyName = event.target.dataset.filter;
    if (propertyName)
      this[propertyName] = event.detail?.value ?? event.target.value;
  }

  handleOnboardingRowAction(event) {
    if (event.detail.action.name !== "open") return;
    const recordId = event.detail.row.onboardingId || event.detail.row.recordId;
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: { recordId, actionName: "view" }
    });
  }

  handleComplianceRowAction(event) {
    if (event.detail.action.name !== "open") return;
    const recordId = event.detail.row.onboardingId || event.detail.row.recordId;
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: { recordId, actionName: "view" }
    });
  }

  handleUnifiedWorkAction(event) {
    if (event.detail.action.name !== "open") return;
    const recordId = event.detail.row.parentId || event.detail.row.recordId;
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: { recordId, actionName: "view" }
    });
  }

  handleDealReview() {
    this.handleNavigation(this.dealReviewTabName);
  }

  handleMdfReview() {
    this.handleNavigation(this.mdfReviewTabName);
  }

  handleNotifications() {
    this.handleNavigation(this.notificationsTabName);
  }

  handleContentAdmin() {
    this.handleNavigation(this.contentAdminTabName);
  }

  handlePartner360() {
    this.handleNavigation(this.partner360TabName);
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

  handleNavigation(apiName) {
    if (!apiName) {
      return;
    }

    this[NavigationMixin.Navigate]({
      type: "comm__namedPage",
      attributes: {
        name: apiName
      }
    });
  }
}
