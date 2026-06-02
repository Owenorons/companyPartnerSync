import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getMyLeads from "@salesforce/apex/LeadDistributionController.getMyLeads";
import processDecision from "@salesforce/apex/LeadDistributionController.processDecision";

export default class PsPartnerLeads extends LightningElement {
  leads = [];
  error;
  loading = true;
  wiredResult;

  @wire(getMyLeads)
  wiredLeads(result) {
    this.wiredResult = result;
    this.loading = false;

    if (result.data) {
      this.leads = result.data.map((lead) => ({
        ...lead,
        badgeClass: this.getBadgeClass(lead.status),
        slaLabel: this.formatDateTime(lead.slaDeadline),
        canRespond: lead.status === "Assigned",
        canConvert: lead.status === "Accepted"
      }));
      this.error = undefined;
    } else if (result.error) {
      this.error = result.error.body?.message || "Unable to load leads.";
      this.leads = [];
    }
  }

  get hasLeads() {
    return this.leads.length > 0;
  }

  async handleAccept(event) {
    await this.submitDecision(event.currentTarget.dataset.id, "Accepted");
  }

  async handleReject(event) {
    await this.submitDecision(event.currentTarget.dataset.id, "Rejected");
  }

  handleConvert(event) {
    this.dispatchEvent(
      new CustomEvent("convertlead", {
        detail: { leadId: event.currentTarget.dataset.id }
      })
    );
  }

  async submitDecision(leadId, decision) {
    try {
      await processDecision({
        request: {
          leadId,
          decision,
          notes: ""
        }
      });

      await refreshApex(this.wiredResult);
    } catch (error) {
      this.error = error.body?.message || "Unable to process lead.";
    }
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

  getBadgeClass(status) {
    if (status === "Accepted" || status === "Converted") {
      return "badge badge-success";
    }

    if (status === "Rejected" || status === "Expired") {
      return "badge badge-danger";
    }

    return "badge badge-warning";
  }
}
