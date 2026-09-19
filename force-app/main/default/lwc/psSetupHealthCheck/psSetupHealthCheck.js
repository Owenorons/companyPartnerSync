import { LightningElement } from "lwc";
import getReadiness from "@salesforce/apex/PartnerSyncSetupController.getReadiness";
import configureOperationalAutomation from "@salesforce/apex/PartnerSyncSetupController.configureOperationalAutomation";

export default class PsSetupHealthCheck extends LightningElement {
  report;
  error;
  loading = true;
  configuringAutomation = false;

  connectedCallback() {
    this.loadReadiness();
  }

  async loadReadiness() {
    this.loading = true;
    this.error = undefined;

    try {
      this.report = await getReadiness();
    } catch (error) {
      this.report = undefined;
      this.error =
        error?.body?.message ||
        error?.message ||
        "PartnerSync readiness could not be checked.";
    } finally {
      this.loading = false;
    }
  }

  get hasReport() {
    return Boolean(this.report);
  }

  get checks() {
    return (this.report?.checks || []).map((check) => ({
      ...check,
      statusLabel: this.statusLabel(check.status),
      variant: this.statusVariant(check.status),
      itemClass: `check-item check-${check.status.toLowerCase()}`
    }));
  }

  get readinessLabel() {
    if (!this.report) {
      return "Not checked";
    }

    return `${this.report.readyCount} of ${this.report.totalCount} checks ready`;
  }

  get coreStatus() {
    return this.report?.coreReady ? "Core ready" : "Core action required";
  }

  get coreVariant() {
    return this.report?.coreReady ? "success" : "error";
  }

  get portalStatus() {
    return this.report?.portalReady ? "Portal ready" : "Portal not ready";
  }

  get portalVariant() {
    return this.report?.portalReady ? "success" : "warning";
  }

  get generatedAt() {
    return this.report?.generatedAt;
  }

  get automationNeedsConfiguration() {
    return (this.report?.checks || []).some(
      (check) =>
        check.key === "scheduled-automation" &&
        check.status === "ACTION_REQUIRED"
    );
  }

  get automationButtonLabel() {
    return this.configuringAutomation
      ? "Configuring automation..."
      : "Configure required jobs";
  }

  handleRefresh() {
    this.loadReadiness();
  }

  async handleConfigureAutomation() {
    if (this.configuringAutomation) return;
    this.configuringAutomation = true;
    this.error = undefined;
    try {
      this.report = await configureOperationalAutomation();
    } catch (error) {
      this.error =
        error?.body?.message ||
        error?.message ||
        "PartnerSync operational jobs could not be configured.";
    } finally {
      this.configuringAutomation = false;
    }
  }

  statusLabel(status) {
    if (status === "ACTION_REQUIRED") {
      return "Action required";
    }
    if (status === "WARNING") {
      return "Review";
    }
    return "Ready";
  }

  statusVariant(status) {
    if (status === "ACTION_REQUIRED") {
      return "danger";
    }
    if (status === "WARNING") {
      return "warning";
    }
    return "success";
  }
}
