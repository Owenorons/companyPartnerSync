import { LightningElement, api, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getExceptions from "@salesforce/apex/PartnerReadinessLifecycleController.getExceptions";
import grantException from "@salesforce/apex/PartnerReadinessLifecycleController.grantException";
import revokeException from "@salesforce/apex/PartnerReadinessLifecycleController.revokeException";

const GATE_OPTIONS = [
  { label: "Documents", value: "documents" },
  { label: "Risk", value: "risk" },
  { label: "Approval", value: "approval" },
  { label: "Agreements", value: "agreements" },
  { label: "Relationship", value: "relationship" },
  { label: "Access", value: "access" },
  { label: "Training", value: "training" }
];

export default class PsPartnerExceptionPanel extends LightningElement {
  @api targetOnboardingId;

  gateOptions = GATE_OPTIONS;
  exceptions = [];
  error;
  actionError;
  submitting = false;
  wiredResult;

  gate = "documents";
  reason = "";
  effectiveOn = new Date().toISOString().slice(0, 10);
  expiresOn;

  @wire(getExceptions, { onboardingId: "$targetOnboardingId" })
  wiredExceptions(result) {
    this.wiredResult = result;

    if (result.data) {
      this.exceptions = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load exceptions."
      );
    }
  }

  get hasExceptions() {
    return this.exceptions.length > 0;
  }

  get exceptionRows() {
    return this.exceptions.map((exception) => ({
      ...exception,
      isActive: exception.Status__c === "Active",
      rowClass:
        exception.Status__c === "Active" ? "status-row active" : "status-row"
    }));
  }

  get isGrantDisabled() {
    return (
      this.submitting || !this.gate || !this.reason.trim() || !this.effectiveOn
    );
  }

  handleGateChange(event) {
    this.gate = event.detail.value;
  }

  handleReasonChange(event) {
    this.reason = event.target.value || "";
  }

  handleEffectiveOnChange(event) {
    this.effectiveOn = event.target.value;
  }

  handleExpiresOnChange(event) {
    this.expiresOn = event.target.value || undefined;
  }

  async handleGrant() {
    if (this.isGrantDisabled) {
      return;
    }

    this.submitting = true;
    this.actionError = undefined;

    try {
      await grantException({
        request: {
          onboardingId: this.targetOnboardingId,
          gate: this.gate,
          reason: this.reason.trim(),
          effectiveOn: this.effectiveOn,
          expiresOn: this.expiresOn
        }
      });

      this.reason = "";
      this.expiresOn = undefined;
      await refreshApex(this.wiredResult);
    } catch (error) {
      this.actionError = this.getErrorMessage(
        error,
        "Unable to grant exception."
      );
    } finally {
      this.submitting = false;
    }
  }

  async handleRevoke(event) {
    if (!this.reason.trim()) {
      this.actionError = "Enter a reason before revoking.";
      return;
    }

    const exceptionId = event.currentTarget.dataset.id;
    this.submitting = true;
    this.actionError = undefined;

    try {
      await revokeException({
        exceptionId,
        reason: this.reason.trim()
      });

      this.reason = "";
      await refreshApex(this.wiredResult);
    } catch (error) {
      this.actionError = this.getErrorMessage(
        error,
        "Unable to revoke exception."
      );
    } finally {
      this.submitting = false;
    }
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
