import { createElement } from "@lwc/engine-dom";
import PsDealReviewWorkspace from "c/psDealReviewWorkspace";
import getReviewQueue from "@salesforce/apex/DealReviewController.getReviewQueue";
import getReviewDetail from "@salesforce/apex/DealReviewController.getReviewDetail";
import processDecision from "@salesforce/apex/DealReviewController.processDecision";

jest.mock(
  "@salesforce/apex/DealReviewController.getReviewQueue",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/DealReviewController.getReviewDetail",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/DealReviewController.processDecision",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-ps-deal-review-workspace", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders review queue rows and loads the first detail", async () => {
    getReviewDetail.mockResolvedValue({
      dealId: "a02xx0000000001",
      dealNumber: "DR-001",
      customerName: "Acme",
      partnerName: "North Partner",
      estimatedRevenue: 25000,
      status: "Submitted",
      conflictStatus: "No Conflict",
      notes: "Qualified opportunity",
      riskScore: 67,
      riskLevel: "Medium",
      riskSummary: "Risk is based on submitted deal data.",
      riskRecommendation: "Review submitted evidence."
    });

    const element = createElement("c-ps-deal-review-workspace", {
      is: PsDealReviewWorkspace
    });

    document.body.appendChild(element);

    getReviewQueue.emit([
      {
        dealId: "a02xx0000000001",
        dealNumber: "DR-001",
        customerName: "Acme",
        partnerName: "North Partner",
        estimatedRevenue: 25000,
        status: "Submitted",
        conflictStatus: "No Conflict"
      }
    ]);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector(".queue-row h3").textContent).toBe(
      "Acme"
    );
    expect(getReviewDetail).toHaveBeenCalledWith({
      dealId: "a02xx0000000001"
    });
    expect(
      element.shadowRoot.querySelector(".notes-body").textContent
    ).toContain("Qualified opportunity");
    expect(element.shadowRoot.querySelector(".risk-score").textContent).toBe(
      "67"
    );
    expect(element.shadowRoot.querySelector(".risk-label").textContent).toBe(
      "Medium Risk"
    );
    expect(element.shadowRoot.querySelector(".risk-score").className).toBe(
      "risk-score risk-medium"
    );
    expect(element.shadowRoot.querySelector(".risk-summary").className).toBe(
      "slds-var-m-top_medium slds-var-p-around_medium risk-summary risk-medium"
    );
  });

  it("submits an approve decision for the selected deal", async () => {
    getReviewDetail.mockResolvedValue({
      dealId: "a02xx0000000001",
      customerName: "Acme",
      partnerName: "North Partner",
      status: "Submitted",
      conflictStatus: "No Conflict",
      canApprove: true,
      canReject: true
    });
    processDecision.mockResolvedValue();

    const element = createElement("c-ps-deal-review-workspace", {
      is: PsDealReviewWorkspace
    });

    document.body.appendChild(element);

    getReviewQueue.emit([
      {
        dealId: "a02xx0000000001",
        customerName: "Acme",
        partnerName: "North Partner",
        status: "Submitted",
        conflictStatus: "No Conflict"
      }
    ]);
    await flushPromises();
    await flushPromises();

    element.shadowRoot.querySelector(".approve").click();
    await flushPromises();

    expect(processDecision).toHaveBeenCalledWith({
      request: expect.objectContaining({
        dealId: "a02xx0000000001",
        decision: "Approved"
      })
    });
  });

  it("requires a rejection reason before submitting a reject decision", async () => {
    getReviewDetail.mockResolvedValue({
      dealId: "a02xx0000000001",
      customerName: "Acme",
      partnerName: "North Partner",
      status: "Submitted",
      conflictStatus: "No Conflict",
      canApprove: true,
      canReject: true
    });
    processDecision.mockResolvedValue();

    const element = createElement("c-ps-deal-review-workspace", {
      is: PsDealReviewWorkspace
    });

    document.body.appendChild(element);

    getReviewQueue.emit([
      {
        dealId: "a02xx0000000001",
        customerName: "Acme",
        partnerName: "North Partner",
        status: "Submitted",
        conflictStatus: "No Conflict"
      }
    ]);
    await flushPromises();
    await flushPromises();

    element.shadowRoot.querySelector(".reject").click();
    await flushPromises();

    const textarea = element.shadowRoot.querySelector("lightning-textarea");
    let rejectButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Reject");

    expect(textarea).not.toBeNull();
    expect(rejectButton.disabled).toBe(true);

    textarea.value = "Insufficient qualification evidence.";
    textarea.dispatchEvent(new CustomEvent("change"));
    await flushPromises();

    rejectButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Reject");

    expect(rejectButton.disabled).toBe(false);

    rejectButton.click();
    await flushPromises();

    expect(processDecision).toHaveBeenCalledWith({
      request: expect.objectContaining({
        dealId: "a02xx0000000001",
        decision: "Rejected",
        rejectionReason: "Insufficient qualification evidence."
      })
    });
  });

  it("renders rejected deals as read-only with the backend rejection reason", async () => {
    getReviewDetail.mockResolvedValue({
      dealId: "a02xx0000000002",
      customerName: "Beta",
      partnerName: "South Partner",
      status: "Rejected",
      conflictStatus: "Potential Conflict",
      rejectionReason: "Customer already protected by another partner.",
      riskScore: 88,
      riskLevel: "High",
      riskSummary: "Risk is based on submitted deal data.",
      riskRecommendation: "Customer already protected by another partner."
    });

    const element = createElement("c-ps-deal-review-workspace", {
      is: PsDealReviewWorkspace
    });

    document.body.appendChild(element);

    getReviewQueue.emit([
      {
        dealId: "a02xx0000000002",
        customerName: "Beta",
        partnerName: "South Partner",
        status: "Rejected",
        conflictStatus: "Potential Conflict"
      }
    ]);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector(".approve")).toBeNull();
    expect(element.shadowRoot.querySelector(".reject")).toBeNull();
    expect(element.shadowRoot.querySelector(".decision-state")).toBeNull();
    expect(element.shadowRoot.querySelector(".stamp").textContent).toBe(
      "Rejected"
    );
    expect(element.shadowRoot.textContent).toContain(
      "Customer already protected by another partner."
    );
  });

  it("hides approve/reject buttons for a viewer without decision permission", async () => {
    getReviewDetail.mockResolvedValue({
      dealId: "a02xx0000000003",
      customerName: "Gamma",
      partnerName: "East Partner",
      status: "Submitted",
      conflictStatus: "No Conflict",
      canApprove: false,
      canReject: false
    });

    const element = createElement("c-ps-deal-review-workspace", {
      is: PsDealReviewWorkspace
    });

    document.body.appendChild(element);

    getReviewQueue.emit([
      {
        dealId: "a02xx0000000003",
        customerName: "Gamma",
        partnerName: "East Partner",
        status: "Submitted",
        conflictStatus: "No Conflict"
      }
    ]);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector(".approve")).toBeNull();
    expect(element.shadowRoot.querySelector(".reject")).toBeNull();
    expect(
      element.shadowRoot.querySelector(".decision-state").textContent
    ).toContain("You do not have permission to decide this deal.");
  });
});
