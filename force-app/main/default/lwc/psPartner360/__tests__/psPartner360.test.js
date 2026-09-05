import { createElement } from "@lwc/engine-dom";
import PsPartner360 from "c/psPartner360";
import getSummary from "@salesforce/apex/Partner360Controller.getSummary";

jest.mock(
  "@salesforce/apex/Partner360Controller.getSummary",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
const flushPromises = async () => {
  await Promise.resolve();
  await Promise.resolve();
  await Promise.resolve();
};

describe("c-ps-partner-360", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("loads and renders the selected partner summary", async () => {
    getSummary.mockResolvedValue({
      partnerName: "Alderbrook Logistics",
      partnerId: "P-001",
      partnerStatus: "Active",
      tier: "Gold",
      partnerType: "Reseller",
      region: "ANZ",
      openDealCount: 3,
      openMdfCount: 1,
      openDocumentCount: 0,
      blockingFindingCount: 1,
      openAccessRequestCount: 2,
      incompleteTrainingCount: 0,
      onboardingStatus: "Active",
      currentStage: "Active",
      activationGateStatus: "Ready",
      relationshipStatus: "Active",
      programmeKey: "RESELLER",
      blockers: ["1 blocking risk findings"],
      recentEvents: [
        {
          recordId: "a1",
          eventType: "Partner Activated",
          stage: "Active",
          summary: "Ready"
        }
      ]
    });
    const element = createElement("c-ps-partner-360", { is: PsPartner360 });
    document.body.appendChild(element);
    const picker = element.shadowRoot.querySelector("lightning-record-picker");
    picker.dispatchEvent(
      new CustomEvent("change", { detail: { recordId: "001000000000001" } })
    );
    await flushPromises();
    expect(getSummary).toHaveBeenCalledWith({
      partnerAccountId: "001000000000001"
    });
    expect(element.shadowRoot.querySelector(".identity").textContent).toContain(
      "Alderbrook Logistics"
    );
    expect(
      element.shadowRoot.querySelectorAll(".metrics c-ps-dashboard-metric-card")
    ).toHaveLength(6);
    expect(element.shadowRoot.querySelector(".timeline").textContent).toContain(
      "Partner Activated"
    );
  });

  it("renders an error returned by the service", async () => {
    getSummary.mockRejectedValue({
      body: { message: "Partner account not found." }
    });
    const element = createElement("c-ps-partner-360", { is: PsPartner360 });
    element.recordId = "001000000000001";
    document.body.appendChild(element);
    await flushPromises();
    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "Partner account not found."
    );
  });
});
