import { LightningElement } from "lwc";
import submitApplication from "@salesforce/apex/PartnerApplicationController.submitApplication";

const TIER_OPTIONS = [
  { label: "Silver", value: "Silver" },
  { label: "Gold", value: "Gold" },
  { label: "Platinum", value: "Platinum" },
  { label: "Strategic", value: "Strategic" }
];

const PARTNER_TYPE_OPTIONS = [
  { label: "Distributor", value: "Distributor" },
  { label: "Reseller", value: "Reseller" },
  { label: "Agent", value: "Agent" },
  { label: "Dealer", value: "Dealer" },
  { label: "Referral", value: "Referral" }
];

export default class PsPartnerApplicationForm extends LightningElement {
  companyName = "";
  businessEmail = "";
  phone = "";
  website = "";
  country = "";
  region = "";
  requestedTier = "";
  partnerType = "";
  submittedByContactName = "";
  submittedByEmail = "";

  error;
  submitting = false;
  result;

  tierOptions = TIER_OPTIONS;
  partnerTypeOptions = PARTNER_TYPE_OPTIONS;

  get isSubmitDisabled() {
    return (
      this.submitting ||
      !this.companyName ||
      !this.businessEmail ||
      !this.requestedTier ||
      !this.partnerType ||
      !this.submittedByEmail
    );
  }

  handleFieldChange(event) {
    this[event.target.name] = event.target.value;
  }

  handleComboboxChange(event) {
    this[event.target.name] = event.detail.value;
  }

  async handleSubmit(event) {
    event.preventDefault();

    if (this.isSubmitDisabled) {
      return;
    }

    this.submitting = true;
    this.error = undefined;

    try {
      this.result = await submitApplication({
        request: {
          companyName: this.companyName,
          businessEmail: this.businessEmail,
          phone: this.phone,
          website: this.website,
          country: this.country,
          region: this.region,
          requestedTier: this.requestedTier,
          partnerType: this.partnerType,
          submittedByContactName: this.submittedByContactName,
          submittedByEmail: this.submittedByEmail
        }
      });
    } catch (error) {
      this.error = this.getErrorMessage(
        error,
        "Unable to submit your application."
      );
    } finally {
      this.submitting = false;
    }
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
