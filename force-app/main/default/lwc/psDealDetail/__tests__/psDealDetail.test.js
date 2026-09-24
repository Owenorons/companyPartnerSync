import { createElement } from "@lwc/engine-dom";
import PsDealDetail from "c/psDealDetail";
import { CurrentPageReference } from "lightning/navigation";
import getDealDetail from "@salesforce/apex/DealRegistrationController.getDealDetail";

jest.mock("lightning/navigation", () => {
  const {
    createTestWireAdapter
  } = require("@salesforce/wire-service-jest-util");

  const NavigationMixin = (Base) => class extends Base {};

  return {
    CurrentPageReference: createTestWireAdapter(jest.fn()),
    NavigationMixin
  };
});

jest.mock(
  "@salesforce/apex/DealRegistrationController.getDealDetail",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

const DEAL_DETAIL = {
  dealId: "a05000000000001",
  dealNumber: "DEAL-001",
  customerName: "Acme Corp",
  partnerName: "North Partner",
  stage: "Proposal",
  status: "Under Review",
  conflictStatus: "No Conflict",
  dealValue: 50000,
  estimatedCloseDate: "2026-12-01",
  protectionEndDate: "2027-01-01",
  businessProblem: "Needs a new platform.",
  proposedSolution: "Deploy PartnerSync.",
  notes: null,
  lifecyclePhase: "Review",
  lifecycleHealth: "Healthy",
  currentActionRequired: null,
  nextActionDue: null,
  createdDate: "2026-09-01T00:00:00.000Z",
  events: [
    {
      eventType: "Submitted",
      summary: "Deal registration submitted for review.",
      occurredOn: "2026-09-01T00:00:00.000Z"
    }
  ]
};

describe("c-ps-deal-detail", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("loads and renders deal detail once the page reference carries a dealId", async () => {
    getDealDetail.mockResolvedValue(DEAL_DETAIL);

    const element = createElement("c-ps-deal-detail", { is: PsDealDetail });
    document.body.appendChild(element);

    CurrentPageReference.emit({ state: { dealId: "a05000000000001" } });
    await flushPromises();
    await flushPromises();

    expect(getDealDetail).toHaveBeenCalledWith({
      dealId: "a05000000000001"
    });
    expect(element.shadowRoot.querySelector("h1").textContent).toBe(
      "Acme Corp"
    );
    expect(
      element.shadowRoot.querySelector(".timeline-row strong").textContent
    ).toBe("Submitted");
  });

  it("shows an error panel when the load fails", async () => {
    getDealDetail.mockRejectedValue({
      body: { message: "Deal not accessible." }
    });

    const element = createElement("c-ps-deal-detail", { is: PsDealDetail });
    document.body.appendChild(element);

    CurrentPageReference.emit({ state: { dealId: "a05000000000002" } });
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "Deal not accessible."
    );
  });
});
