import { api, LightningElement, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getEligibleOpportunities from "@salesforce/apex/DealRegistrationController.getEligibleOpportunities";
import createDealRegistration from "@salesforce/apex/DealRegistrationController.createDealRegistration";

export default class PsDealRegistrationForm extends NavigationMixin(
  LightningElement
) {
  @api dealsPageName = "My-Deals";

  opportunities = [];
  error;
  loading = true;
  submitting = false;
  result;

  selectedOpportunityId = "";
  businessProblem = "";
  proposedSolution = "";
  estimatedRevenue;
  estimatedCloseDate;
  implementationTimeline = "";
  notes = "";

  @wire(getEligibleOpportunities)
  wiredOpportunities({ data, error }) {
    this.loading = false;

    if (data) {
      this.opportunities = Array.isArray(data) ? data : [];
      this.error = undefined;
    } else if (error) {
      this.error = this.getErrorMessage(error, "Unable to load opportunities.");
      this.opportunities = [];
    }
  }

  get hasOpportunities() {
    return this.opportunities.length > 0;
  }

  get opportunityOptions() {
    return this.opportunities.map((opportunity) => ({
      label: opportunity.name,
      value: opportunity.opportunityId
    }));
  }

  get isSubmitDisabled() {
    return this.submitting || !this.selectedOpportunityId;
  }

  handleOpportunityChange(event) {
    this.selectedOpportunityId = event.detail.value;
  }

  handleFieldChange(event) {
    this[event.target.name] = event.target.value;
  }

  async handleSubmit(event) {
    event.preventDefault();

    if (this.isSubmitDisabled) {
      return;
    }

    this.submitting = true;
    this.error = undefined;

    try {
      this.result = await createDealRegistration({
        request: {
          opportunityId: this.selectedOpportunityId,
          businessProblem: this.businessProblem,
          proposedSolution: this.proposedSolution,
          estimatedRevenue: this.estimatedRevenue
            ? Number(this.estimatedRevenue)
            : null,
          estimatedCloseDate: this.estimatedCloseDate,
          implementationTimeline: this.implementationTimeline,
          notes: this.notes
        }
      });
    } catch (error) {
      this.error = this.getErrorMessage(
        error,
        "Unable to submit deal registration."
      );
    } finally {
      this.submitting = false;
    }
  }

  handleViewDeals() {
    if (!this.dealsPageName) {
      return;
    }

    this[NavigationMixin.Navigate]({
      type: "comm__namedPage",
      attributes: {
        name: this.dealsPageName
      }
    });
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
