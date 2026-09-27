import { createElement } from "@lwc/engine-dom";
import PsPartnerDealTeam from "c/psPartnerDealTeam";
import getDealTeam from "@salesforce/apex/DealParticipantController.getDealTeam";
import executeCommand from "@salesforce/apex/DealParticipantController.executeCommand";

jest.mock(
  "@salesforce/apex/DealParticipantController.getDealTeam",
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

describe("c-ps-partner-deal-team", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders the deal team and shows accept/decline only for the current user's own pending row", async () => {
    const element = createElement("c-ps-partner-deal-team", {
      is: PsPartnerDealTeam
    });
    element.recordId = "a0Bxx000000001";
    document.body.appendChild(element);

    getDealTeam.emit([
      {
        participantId: "a0Cxx000000001",
        organisationName: "Originating Partner",
        participantRole: "Deal Owner",
        status: "Active",
        isOwnOrganisation: false,
        canAccept: false,
        canDecline: false,
        versionNumber: 0
      },
      {
        participantId: "a0Cxx000000002",
        organisationName: "Co-Sell Partner",
        participantRole: "Co-Sell Contributor",
        status: "Invited",
        isOwnOrganisation: true,
        canAccept: true,
        canDecline: true,
        versionNumber: 0
      }
    ]);
    await flushPromises();

    const cards = element.shadowRoot.querySelectorAll(".team-card");
    expect(cards).toHaveLength(2);
    expect(element.shadowRoot.querySelectorAll("button.accept")).toHaveLength(
      1
    );
  });

  it("submits an accept decision for the current user's own participant row", async () => {
    executeCommand.mockResolvedValue({
      participantId: "a0Cxx000000002",
      status: "Accepted"
    });
    const element = createElement("c-ps-partner-deal-team", {
      is: PsPartnerDealTeam
    });
    element.recordId = "a0Bxx000000001";
    document.body.appendChild(element);

    getDealTeam.emit([
      {
        participantId: "a0Cxx000000002",
        organisationName: "Co-Sell Partner",
        participantRole: "Co-Sell Contributor",
        status: "Invited",
        isOwnOrganisation: true,
        canAccept: true,
        canDecline: true,
        versionNumber: 0
      }
    ]);
    await flushPromises();

    element.shadowRoot.querySelector("button.accept").click();
    await flushPromises();

    expect(executeCommand).toHaveBeenCalledWith({
      command: {
        participantId: "a0Cxx000000002",
        action: "Accept",
        expectedVersion: 0
      }
    });
  });

  it("shows server errors without leaving stale team cards", async () => {
    const element = createElement("c-ps-partner-deal-team", {
      is: PsPartnerDealTeam
    });
    element.recordId = "a0Bxx000000001";
    document.body.appendChild(element);

    getDealTeam.error({ body: { message: "Deal access denied." } });
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "Unable to load the deal team."
    );
    expect(element.shadowRoot.querySelectorAll(".team-card")).toHaveLength(0);
  });
});
