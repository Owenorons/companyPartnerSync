import { createElement } from "@lwc/engine-dom";
import PsPartnerOperationsCommandCenter from "c/psPartnerOperationsCommandCenter";
import getOperationsSummary from "@salesforce/apex/PartnerOperationsCommandCenterController.getOperationsSummary";

const mockNavigate = jest.fn();

jest.mock("lightning/navigation", () => {
  const Navigate = Symbol("Navigate");

  const NavigationMixin = (Base) =>
    class extends Base {
      [Navigate](...args) {
        mockNavigate(...args);
      }
    };
  NavigationMixin.Navigate = Navigate;

  return { NavigationMixin };
});

jest.mock(
  "@salesforce/apex/PartnerOperationsCommandCenterController.getOperationsSummary",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

const SUMMARY = {
  pendingHandoffCount: 1,
  atRiskEngagementCount: 2,
  renewalsDueCount: 3,
  partnerConfirmationRequiredCount: 4,
  openExpansionCount: 5,
  pendingReassignmentCount: 6,
  openDisputeCount: 7,
  proposedRecommendationCount: 8
};

describe("c-ps-partner-operations-command-center", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders one queue card per count in the operations summary", async () => {
    const element = createElement("c-ps-partner-operations-command-center", {
      is: PsPartnerOperationsCommandCenter
    });
    document.body.appendChild(element);

    getOperationsSummary.emit(SUMMARY);
    await flushPromises();

    const cards = element.shadowRoot.querySelectorAll(".queue-card");
    expect(cards).toHaveLength(8);
    expect(
      Array.from(cards).map((card) => card.querySelector("h2").textContent)
    ).toEqual(["1", "2", "3", "4", "5", "6", "7", "8"]);
  });

  it("navigates to the finance workbench when the open disputes queue is selected", async () => {
    const element = createElement("c-ps-partner-operations-command-center", {
      is: PsPartnerOperationsCommandCenter
    });
    document.body.appendChild(element);

    getOperationsSummary.emit(SUMMARY);
    await flushPromises();

    const cards = Array.from(
      element.shadowRoot.querySelectorAll(".queue-card")
    );
    const disputesCard = cards.find((card) =>
      card.textContent.includes("Open Revenue Disputes")
    );
    disputesCard.click();
    await flushPromises();

    expect(mockNavigate).toHaveBeenCalledWith({
      type: "comm__namedPage",
      attributes: { name: "Finance_Workbench__c" }
    });
  });

  it("shows an error panel when the summary wire fails", async () => {
    const element = createElement("c-ps-partner-operations-command-center", {
      is: PsPartnerOperationsCommandCenter
    });
    document.body.appendChild(element);

    getOperationsSummary.error({
      body: { message: "Internal access required." }
    });
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "Unable to load the operations summary."
    );
  });
});
