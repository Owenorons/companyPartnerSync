import { LightningElement, api, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getMyConsents from "@salesforce/apex/PartnerConsentController.getMyConsents";
import acceptConsent from "@salesforce/apex/PartnerConsentController.acceptConsent";
import revokeConsent from "@salesforce/apex/PartnerConsentController.revokeConsent";

export default class PsPartnerConsentPanel extends LightningElement {
  @api policyKey = "Partner Program Terms";
  @api policyVersion = "2026.1";
  @api policyLabel = "Partner Program Terms";

  consents = [];
  error;
  actionError;
  submitting = false;
  wiredResult;

  @wire(getMyConsents)
  wiredConsents(result) {
    this.wiredResult = result;

    if (result.data) {
      this.consents = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load your consents."
      );
    }
  }

  get currentConsent() {
    return this.consents.find(
      (consent) =>
        consent.Policy_Key__c === this.policyKey &&
        consent.Policy_Version__c === this.policyVersion &&
        consent.Status__c === "Active"
    );
  }

  get isAccepted() {
    return Boolean(this.currentConsent);
  }

  get acceptedOnLabel() {
    if (!this.currentConsent?.Accepted_On__c) {
      return "";
    }

    return new Intl.DateTimeFormat("en-AU", {
      dateStyle: "medium",
      timeStyle: "short"
    }).format(new Date(this.currentConsent.Accepted_On__c));
  }

  async handleAccept() {
    this.submitting = true;
    this.actionError = undefined;

    try {
      await acceptConsent({
        policyKey: this.policyKey,
        policyVersion: this.policyVersion
      });

      await refreshApex(this.wiredResult);
    } catch (error) {
      this.actionError = this.getErrorMessage(
        error,
        "Unable to record your acceptance."
      );
    } finally {
      this.submitting = false;
    }
  }

  async handleRevoke() {
    if (!this.currentConsent) {
      return;
    }

    this.submitting = true;
    this.actionError = undefined;

    try {
      await revokeConsent({ consentId: this.currentConsent.Id });
      await refreshApex(this.wiredResult);
    } catch (error) {
      this.actionError = this.getErrorMessage(
        error,
        "Unable to revoke your acceptance."
      );
    } finally {
      this.submitting = false;
    }
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
