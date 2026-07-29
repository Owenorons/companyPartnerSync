import { LightningElement, api, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getActiveShares from "@salesforce/apex/PartnerShareController.getActiveShares";
import grantAccess from "@salesforce/apex/PartnerShareController.grantAccess";
import revokeAccess from "@salesforce/apex/PartnerShareController.revokeAccess";

const ACCESS_LEVEL_OPTIONS = [
  { label: "Read", value: "Read" },
  { label: "Edit", value: "Edit" },
  { label: "Review", value: "Review" },
  { label: "Approve", value: "Approve" }
];

// Only the two target objects PartnerShareService actually implements
// Salesforce sharing for today. Keep this in sync with
// PartnerShareService.createSalesforceShare/deleteSalesforceShare.
const TARGET_OBJECT_LABELS = {
  Deal_Registration__c: "Deal Registration",
  MDF_Request__c: "MDF Request"
};

const PARTNER_ACCOUNT_FILTER = {
  criteria: [{ fieldPath: "Is_Partner__c", operator: "eq", value: true }]
};

export default class PsPartnerShareManager extends LightningElement {
  @api recordId;
  @api objectApiName;

  shares = [];
  error;
  wiredSharesResult;

  showForm = false;
  submitting = false;
  formError;

  selectedPartnerAccountId;
  accessLevel = "Read";
  shareReason = "";
  expiryDate;

  accessLevelOptions = ACCESS_LEVEL_OPTIONS;
  partnerAccountFilter = PARTNER_ACCOUNT_FILTER;

  @wire(getActiveShares, { targetRecordId: "$recordId" })
  wiredShares(result) {
    this.wiredSharesResult = result;

    if (result.data) {
      this.shares = result.data.map((share) => this.toViewModel(share));
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load record shares."
      );
      this.shares = [];
    }
  }

  get targetObjectLabel() {
    return TARGET_OBJECT_LABELS[this.objectApiName];
  }

  get isSupportedObject() {
    return Boolean(this.targetObjectLabel);
  }

  get hasShares() {
    return this.shares.length > 0;
  }

  get toggleButtonLabel() {
    return this.showForm ? "Cancel" : "Grant Access";
  }

  get isGrantDisabled() {
    return (
      this.submitting ||
      !this.selectedPartnerAccountId ||
      !this.accessLevel ||
      !this.shareReason.trim()
    );
  }

  handleToggleForm() {
    this.showForm = !this.showForm;
    this.formError = undefined;
  }

  handlePartnerAccountChange(event) {
    this.selectedPartnerAccountId = event.detail.recordId;
  }

  handleAccessLevelChange(event) {
    this.accessLevel = event.detail.value;
  }

  handleShareReasonChange(event) {
    this.shareReason = event.target.value || "";
  }

  handleExpiryDateChange(event) {
    this.expiryDate = event.target.value || null;
  }

  async handleGrant() {
    if (this.isGrantDisabled) {
      return;
    }

    this.submitting = true;
    this.formError = undefined;

    try {
      await grantAccess({
        request: {
          targetRecordId: this.recordId,
          targetObject: this.targetObjectLabel,
          partnerAccountId: this.selectedPartnerAccountId,
          accessLevel: this.accessLevel,
          shareReason: this.shareReason.trim(),
          expiryDate: this.expiryDate
        }
      });

      await refreshApex(this.wiredSharesResult);
      this.resetForm();
      this.showForm = false;
    } catch (error) {
      this.formError = this.getErrorMessage(error, "Unable to grant access.");
    } finally {
      this.submitting = false;
    }
  }

  async handleRevoke(event) {
    const shareId = event.currentTarget.dataset.id;

    try {
      await revokeAccess({ partnerRecordShareId: shareId });
      await refreshApex(this.wiredSharesResult);
    } catch (error) {
      this.error = this.getErrorMessage(error, "Unable to revoke access.");
    }
  }

  resetForm() {
    this.selectedPartnerAccountId = undefined;
    this.accessLevel = "Read";
    this.shareReason = "";
    this.expiryDate = undefined;
  }

  toViewModel(share) {
    return {
      ...share,
      expiryLabel: this.formatDate(share.expiryDate),
      grantedOnLabel: this.formatDateTime(share.grantedOn)
    };
  }

  formatDate(value) {
    if (!value) {
      return "No expiry";
    }

    return new Intl.DateTimeFormat("en-AU", { dateStyle: "medium" }).format(
      new Date(value)
    );
  }

  formatDateTime(value) {
    if (!value) {
      return "Unknown";
    }

    return new Intl.DateTimeFormat("en-AU", {
      dateStyle: "medium",
      timeStyle: "short"
    }).format(new Date(value));
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
