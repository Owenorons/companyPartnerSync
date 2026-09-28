import { createElement } from "@lwc/engine-dom";
import PsPortfolioIntelligencePanel from "c/psPortfolioIntelligencePanel";
import getAllSnapshots from "@salesforce/apex/PortfolioIntelligenceController.getAllSnapshots";
import getProposedRecommendations from "@salesforce/apex/PortfolioIntelligenceController.getProposedRecommendations";
import executeRecommendation from "@salesforce/apex/PortfolioIntelligenceController.executeRecommendation";

function mockWireAdapter() {
  const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
  return { default: createApexTestWireAdapter(jest.fn()) };
}

jest.mock(
  "@salesforce/apex/PortfolioIntelligenceController.getAllSnapshots",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/PortfolioIntelligenceController.getProposedRecommendations",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/PortfolioIntelligenceController.executeRecommendation",
  () => ({ default: jest.fn(() => Promise.resolve({})) }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-ps-portfolio-intelligence-panel", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders portfolio snapshots and proposed recommendations", async () => {
    const element = createElement("c-ps-portfolio-intelligence-panel", {
      is: PsPortfolioIntelligencePanel
    });
    document.body.appendChild(element);

    getAllSnapshots.emit([
      {
        Id: "a0Vxx000000001",
        Partner_Account__r: { Name: "Acme Partner" },
        Health_Score__c: 55,
        Health_Label__c: "Developing"
      }
    ]);
    getProposedRecommendations.emit([
      {
        Id: "a0Wxx000000001",
        Partner_Account__r: { Name: "Acme Partner" },
        Recommendation_Text__c: "Consider a review."
      }
    ]);
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(2);
  });

  it("executes a recommendation when the execute button is clicked", async () => {
    const element = createElement("c-ps-portfolio-intelligence-panel", {
      is: PsPortfolioIntelligencePanel
    });
    document.body.appendChild(element);

    getAllSnapshots.emit([]);
    getProposedRecommendations.emit([
      {
        Id: "a0Wxx000000002",
        Partner_Account__r: { Name: "Acme Partner" },
        Recommendation_Text__c: "Consider a review."
      }
    ]);
    await flushPromises();

    element.shadowRoot.querySelector(".action-button-execute").click();
    await flushPromises();

    expect(executeRecommendation).toHaveBeenCalledWith({
      recommendationId: "a0Wxx000000002",
      reason: null
    });
  });

  it("shows an error panel when a wire fails", async () => {
    const element = createElement("c-ps-portfolio-intelligence-panel", {
      is: PsPortfolioIntelligencePanel
    });
    document.body.appendChild(element);

    getAllSnapshots.error({
      body: { message: "Portfolio intelligence access denied." }
    });
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "Unable to load portfolio snapshots."
    );
  });
});
