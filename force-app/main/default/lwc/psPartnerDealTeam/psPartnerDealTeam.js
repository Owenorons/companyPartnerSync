import { LightningElement, api, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getDealTeam from "@salesforce/apex/DealParticipantController.getDealTeam";
import executeCommand from "@salesforce/apex/DealParticipantController.executeCommand";

export default class PsPartnerDealTeam extends LightningElement {
  @api recordId;

  participants = [];
  error;
  loading = true;
  wiredResult;

  @wire(getDealTeam, { dealId: "$recordId" })
  wiredTeam(result) {
    this.wiredResult = result;
    this.loading = false;

    if (result.data) {
      this.participants = result.data.map((row) => ({
        ...row,
        badgeVariant: this.getBadgeVariant(row.status)
      }));
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load the deal team."
      );
      this.participants = [];
    }
  }

  get hasParticipants() {
    return this.participants.length > 0;
  }

  async handleAccept(event) {
    await this.submitDecision(event.currentTarget.dataset.id, "Accept");
  }

  async handleDecline(event) {
    await this.submitDecision(event.currentTarget.dataset.id, "Decline");
  }

  async submitDecision(participantId, action) {
    const row = this.participants.find(
      (p) => p.participantId === participantId
    );

    try {
      await executeCommand({
        command: {
          participantId,
          action,
          expectedVersion: row ? row.versionNumber : null
        }
      });

      await refreshApex(this.wiredResult);
    } catch (error) {
      this.error = this.getErrorMessage(
        error,
        "Unable to process the invitation."
      );
    }
  }

  getBadgeVariant(status) {
    if (status === "Active" || status === "Accepted") {
      return "success";
    }
    if (status === "Declined" || status === "Removed" || status === "Expired") {
      return "danger";
    }
    if (status === "Suspended") {
      return "warning";
    }
    return "info";
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
