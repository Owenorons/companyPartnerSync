import { createElement } from "@lwc/engine-dom";
import PsDealCoSellWorkbench from "c/psDealCoSellWorkbench";
import getPendingInvitations from "@salesforce/apex/DealParticipantController.getPendingInvitations";
import getActiveCoSellDeals from "@salesforce/apex/DealParticipantController.getActiveCoSellDeals";
import getParticipantChanges from "@salesforce/apex/DealParticipantController.getParticipantChanges";
import getPendingSharedProtectionRequests from "@salesforce/apex/DealParticipantController.getPendingSharedProtectionRequests";
import approveSharedProtectionRequest from "@salesforce/apex/DealParticipantController.approveSharedProtectionRequest";
import getRelationshipExceptions from "@salesforce/apex/DealParticipantController.getRelationshipExceptions";
import getSlaBreaches from "@salesforce/apex/DealParticipantController.getSlaBreaches";
import executeCommand from "@salesforce/apex/DealParticipantController.executeCommand";

jest.mock(
  "@salesforce/apex/DealParticipantController.getPendingInvitations",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/DealParticipantController.getActiveCoSellDeals",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/DealParticipantController.getParticipantChanges",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/DealParticipantController.getPendingSharedProtectionRequests",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/DealParticipantController.approveSharedProtectionRequest",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/DealParticipantController.getRelationshipExceptions",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/DealParticipantController.getSlaBreaches",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/DealParticipantController.executeCommand",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

function selectTab(element, tabName) {
  element.shadowRoot.querySelector(`button[data-tab="${tabName}"]`).click();
}

describe("c-ps-deal-co-sell-workbench", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders pending invitations", async () => {
    const element = createElement("c-ps-deal-co-sell-workbench", {
      is: PsDealCoSellWorkbench
    });
    document.body.appendChild(element);

    getPendingInvitations.emit([
      {
        participantId: "a0Cxx000000001",
        organisationName: "Co-Sell Partner",
        participantType: "Co-Sell Partner",
        participantRole: "Co-Sell Contributor",
        status: "Invited",
        respondBy: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
        versionNumber: 0
      }
    ]);
    await flushPromises();

    const cards = element.shadowRoot.querySelectorAll(".invitation-card");
    expect(cards).toHaveLength(1);
  });

  it("removes a pending invitation", async () => {
    executeCommand.mockResolvedValue({});
    const element = createElement("c-ps-deal-co-sell-workbench", {
      is: PsDealCoSellWorkbench
    });
    document.body.appendChild(element);

    getPendingInvitations.emit([
      {
        participantId: "a0Cxx000000001",
        organisationName: "Co-Sell Partner",
        participantType: "Co-Sell Partner",
        participantRole: "Co-Sell Contributor",
        status: "Invited",
        respondBy: null,
        versionNumber: 0
      }
    ]);
    await flushPromises();

    element.shadowRoot.querySelector("button.remove").click();
    await flushPromises();

    expect(executeCommand).toHaveBeenCalledWith({
      command: {
        participantId: "a0Cxx000000001",
        action: "Remove",
        expectedVersion: 0,
        reason: "Removed from the co-sell workbench."
      }
    });
  });

  it("shows server errors without leaving stale invitation cards", async () => {
    const element = createElement("c-ps-deal-co-sell-workbench", {
      is: PsDealCoSellWorkbench
    });
    document.body.appendChild(element);

    getPendingInvitations.error({
      body: { message: "Workbench access denied." }
    });
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "Unable to load pending invitations."
    );
    expect(
      element.shadowRoot.querySelectorAll(".invitation-card")
    ).toHaveLength(0);
  });

  it("renders active co-sell deals on the co-sell deals tab", async () => {
    const element = createElement("c-ps-deal-co-sell-workbench", {
      is: PsDealCoSellWorkbench
    });
    document.body.appendChild(element);

    getActiveCoSellDeals.emit([
      {
        dealId: "a0Dxx000000001",
        customerName: "Acme Co",
        originatingPartnerName: "Originating Partner",
        coSellStatus: "Active",
        activeParticipantCount: 2
      }
    ]);
    await flushPromises();

    selectTab(element, "coSellDeals");
    await flushPromises();

    const cards = element.shadowRoot.querySelectorAll(".invitation-card");
    expect(cards).toHaveLength(1);
  });

  it("renders participant changes on the changes tab", async () => {
    const element = createElement("c-ps-deal-co-sell-workbench", {
      is: PsDealCoSellWorkbench
    });
    document.body.appendChild(element);

    getParticipantChanges.emit([
      {
        dealId: "a0Dxx000000001",
        action: "Invite Participant",
        performedByName: "Internal User",
        performedOn: new Date().toISOString()
      }
    ]);
    await flushPromises();

    selectTab(element, "changes");
    await flushPromises();

    const cards = element.shadowRoot.querySelectorAll(".invitation-card");
    expect(cards).toHaveLength(1);
  });

  it("renders and approves a shared protection request", async () => {
    approveSharedProtectionRequest.mockResolvedValue();
    const element = createElement("c-ps-deal-co-sell-workbench", {
      is: PsDealCoSellWorkbench
    });
    document.body.appendChild(element);

    getPendingSharedProtectionRequests.emit([
      {
        protectionParticipantId: "a0Exx000000001",
        dealId: "a0Dxx000000001",
        participantOrganisationName: "Co-Sell Partner",
        protectionRole: "Shared Protected Partner",
        sharePercentage: 40,
        requestedOn: new Date().toISOString(),
        grantVersionNumber: 1
      }
    ]);
    await flushPromises();

    selectTab(element, "protectionRequests");
    await flushPromises();

    expect(
      element.shadowRoot.querySelectorAll(".invitation-card")
    ).toHaveLength(1);

    element.shadowRoot.querySelector("button.approve").click();
    await flushPromises();

    expect(approveSharedProtectionRequest).toHaveBeenCalledWith({
      protectionParticipantId: "a0Exx000000001",
      expectedGrantVersion: 1
    });
  });

  it("renders relationship exceptions on the exceptions tab", async () => {
    const element = createElement("c-ps-deal-co-sell-workbench", {
      is: PsDealCoSellWorkbench
    });
    document.body.appendChild(element);

    getRelationshipExceptions.emit([
      {
        relationshipId: "a0Fxx000000001",
        sourceAccountName: "Source",
        targetAccountName: "Target",
        status: "Suspended",
        effectiveTo: new Date().toISOString()
      }
    ]);
    await flushPromises();

    selectTab(element, "exceptions");
    await flushPromises();

    const cards = element.shadowRoot.querySelectorAll(".invitation-card");
    expect(cards).toHaveLength(1);
  });

  it("renders SLA breaches on the sla breaches tab", async () => {
    const element = createElement("c-ps-deal-co-sell-workbench", {
      is: PsDealCoSellWorkbench
    });
    document.body.appendChild(element);

    getSlaBreaches.emit([
      {
        participantId: "a0Cxx000000002",
        organisationName: "Co-Sell Partner",
        participantType: "Co-Sell Partner",
        participantRole: "Co-Sell Contributor",
        status: "Expired",
        respondBy: new Date().toISOString(),
        versionNumber: 0
      }
    ]);
    await flushPromises();

    selectTab(element, "slaBreaches");
    await flushPromises();

    const cards = element.shadowRoot.querySelectorAll(".invitation-card");
    expect(cards).toHaveLength(1);
  });
});
