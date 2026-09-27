import { createElement } from "@lwc/engine-dom";
import PsPartnerSalesProgress from "c/psPartnerSalesProgress";
import getSalesProgress from "@salesforce/apex/DealOpportunityController.getSalesProgress";

jest.mock(
  "@salesforce/apex/DealOpportunityController.getSalesProgress",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-ps-partner-sales-progress", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders the sales progress summary", async () => {
    const element = createElement("c-ps-partner-sales-progress", {
      is: PsPartnerSalesProgress
    });
    element.dealId = "a0Dxx000000001";
    document.body.appendChild(element);

    getSalesProgress.emit({
      dealId: "a0Dxx000000001",
      stage: "Proposal",
      isWon: false,
      isClosed: false,
      amount: 50000,
      closeDate: "2026-12-01",
      opportunityCount: 1
    });
    await flushPromises();

    const card = element.shadowRoot.querySelector(".sales-progress-card");
    expect(card).not.toBeNull();
    expect(card.textContent).toContain("Proposal");
  });

  it("shows an error panel when the wire fails", async () => {
    const element = createElement("c-ps-partner-sales-progress", {
      is: PsPartnerSalesProgress
    });
    element.dealId = "a0Dxx000000001";
    document.body.appendChild(element);

    getSalesProgress.error({ message: "This deal is not accessible." });
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "This deal is not accessible."
    );
    expect(element.shadowRoot.querySelector(".sales-progress-card")).toBeNull();
  });
});
