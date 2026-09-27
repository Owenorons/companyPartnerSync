import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getPendingInvitations from "@salesforce/apex/DealParticipantController.getPendingInvitations";
import getActiveCoSellDeals from "@salesforce/apex/DealParticipantController.getActiveCoSellDeals";
import getParticipantChanges from "@salesforce/apex/DealParticipantController.getParticipantChanges";
import getPendingSharedProtectionRequests from "@salesforce/apex/DealParticipantController.getPendingSharedProtectionRequests";
import approveSharedProtectionRequest from "@salesforce/apex/DealParticipantController.approveSharedProtectionRequest";
import getRelationshipExceptions from "@salesforce/apex/DealParticipantController.getRelationshipExceptions";
import getSlaBreaches from "@salesforce/apex/DealParticipantController.getSlaBreaches";
import executeCommand from "@salesforce/apex/DealParticipantController.executeCommand";

const TABS = [
  { name: "invitations", label: "Pending Invitations" },
  { name: "coSellDeals", label: "Active Co-Sell Deals" },
  { name: "changes", label: "Participant Changes" },
  { name: "protectionRequests", label: "Shared Protection Requests" },
  { name: "exceptions", label: "Relationship Exceptions" },
  { name: "slaBreaches", label: "Participant SLA Breaches" }
];

export default class PsDealCoSellWorkbench extends LightningElement {
  activeTab = "invitations";

  invitations = [];
  coSellDeals = [];
  changes = [];
  protectionRequests = [];
  exceptions = [];
  slaBreaches = [];

  error;
  loading = true;

  wiredInvitationsResult;
  wiredCoSellDealsResult;
  wiredChangesResult;
  wiredProtectionRequestsResult;
  wiredExceptionsResult;
  wiredSlaBreachesResult;

  get tabs() {
    return TABS.map((tab) => ({
      ...tab,
      className:
        tab.name === this.activeTab
          ? "tab-button tab-button-active"
          : "tab-button"
    }));
  }

  get isInvitationsTab() {
    return this.activeTab === "invitations";
  }

  get isCoSellDealsTab() {
    return this.activeTab === "coSellDeals";
  }

  get isChangesTab() {
    return this.activeTab === "changes";
  }

  get isProtectionRequestsTab() {
    return this.activeTab === "protectionRequests";
  }

  get isExceptionsTab() {
    return this.activeTab === "exceptions";
  }

  get isSlaBreachesTab() {
    return this.activeTab === "slaBreaches";
  }

  handleSelectTab(event) {
    this.activeTab = event.currentTarget.dataset.tab;
  }

  @wire(getPendingInvitations)
  wiredInvitations(result) {
    this.wiredInvitationsResult = result;
    this.loading = false;

    if (result.data) {
      this.invitations = result.data.map((row) => ({
        ...row,
        respondByLabel: this.formatDateTime(row.respondBy)
      }));
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load pending invitations."
      );
      this.invitations = [];
    }
  }

  @wire(getActiveCoSellDeals)
  wiredCoSellDeals(result) {
    this.wiredCoSellDealsResult = result;

    if (result.data) {
      this.coSellDeals = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load active co-sell deals."
      );
      this.coSellDeals = [];
    }
  }

  @wire(getParticipantChanges)
  wiredChanges(result) {
    this.wiredChangesResult = result;

    if (result.data) {
      this.changes = result.data.map((row, index) => ({
        ...row,
        changeKey: `${row.dealId || "unknown"}-${row.action}-${index}`,
        performedOnLabel: this.formatDateTime(row.performedOn)
      }));
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load participant changes."
      );
      this.changes = [];
    }
  }

  @wire(getPendingSharedProtectionRequests)
  wiredProtectionRequests(result) {
    this.wiredProtectionRequestsResult = result;

    if (result.data) {
      this.protectionRequests = result.data.map((row) => ({
        ...row,
        requestedOnLabel: this.formatDateTime(row.requestedOn)
      }));
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load shared protection requests."
      );
      this.protectionRequests = [];
    }
  }

  @wire(getRelationshipExceptions)
  wiredExceptions(result) {
    this.wiredExceptionsResult = result;

    if (result.data) {
      this.exceptions = result.data.map((row) => ({
        ...row,
        effectiveToLabel: this.formatDate(row.effectiveTo)
      }));
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load relationship exceptions."
      );
      this.exceptions = [];
    }
  }

  @wire(getSlaBreaches)
  wiredSlaBreaches(result) {
    this.wiredSlaBreachesResult = result;

    if (result.data) {
      this.slaBreaches = result.data.map((row) => ({
        ...row,
        respondByLabel: this.formatDateTime(row.respondBy)
      }));
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load participant SLA breaches."
      );
      this.slaBreaches = [];
    }
  }

  get hasInvitations() {
    return this.invitations.length > 0;
  }

  get hasCoSellDeals() {
    return this.coSellDeals.length > 0;
  }

  get hasChanges() {
    return this.changes.length > 0;
  }

  get hasProtectionRequests() {
    return this.protectionRequests.length > 0;
  }

  get hasExceptions() {
    return this.exceptions.length > 0;
  }

  get hasSlaBreaches() {
    return this.slaBreaches.length > 0;
  }

  async handleRemove(event) {
    const participantId = event.currentTarget.dataset.id;
    const row = this.invitations.find(
      (invitation) => invitation.participantId === participantId
    );

    try {
      await executeCommand({
        command: {
          participantId,
          action: "Remove",
          expectedVersion: row ? row.versionNumber : null,
          reason: "Removed from the co-sell workbench."
        }
      });

      await refreshApex(this.wiredInvitationsResult);
    } catch (error) {
      this.error = this.getErrorMessage(
        error,
        "Unable to remove the participant."
      );
    }
  }

  async handleApprove(event) {
    const protectionParticipantId = event.currentTarget.dataset.id;
    const row = this.protectionRequests.find(
      (request) => request.protectionParticipantId === protectionParticipantId
    );

    try {
      await approveSharedProtectionRequest({
        protectionParticipantId,
        expectedGrantVersion: row ? row.grantVersionNumber : null
      });

      await refreshApex(this.wiredProtectionRequestsResult);
    } catch (error) {
      this.error = this.getErrorMessage(
        error,
        "Unable to approve the shared protection request."
      );
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

  formatDate(value) {
    if (!value) {
      return "Not set";
    }

    return new Intl.DateTimeFormat("en-AU", {
      dateStyle: "medium"
    }).format(new Date(value));
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
