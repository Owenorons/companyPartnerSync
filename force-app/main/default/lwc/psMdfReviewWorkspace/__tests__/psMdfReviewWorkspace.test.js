import { createElement } from "@lwc/engine-dom";
import PsMdfReviewWorkspace from "c/psMdfReviewWorkspace";
import getReviewQueue from "@salesforce/apex/MDFController.getReviewQueue";
import processDecision from "@salesforce/apex/MDFController.processDecision";

jest.mock(
  "@salesforce/apex/MDFController.getReviewQueue",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/MDFController.processDecision",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

const QUEUE_ROW = {
  requestId: "a03xx0000000001",
  requestNumber: "MDF-001",
  partnerName: "North Partner",
  campaignName: "Q3 Field Event",
  requestType: "Event",
  requestedAmount: 5000,
  approvedAmount: null,
  status: "Submitted",
  startDate: "2026-08-01",
  endDate: "2026-08-15"
};

describe("c-ps-mdf-review-workspace", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders review queue rows and selects the first request", async () => {
    const element = createElement("c-ps-mdf-review-workspace", {
      is: PsMdfReviewWorkspace
    });

    document.body.appendChild(element);

    getReviewQueue.emit([QUEUE_ROW]);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector(".queue-row h3").textContent).toBe(
      "Q3 Field Event"
    );
    expect(element.shadowRoot.querySelector(".hero-card h2").textContent).toBe(
      "Q3 Field Event"
    );
  });

  it("submits an approve decision with the entered amount", async () => {
    processDecision.mockResolvedValue();

    const element = createElement("c-ps-mdf-review-workspace", {
      is: PsMdfReviewWorkspace
    });

    document.body.appendChild(element);

    getReviewQueue.emit([QUEUE_ROW]);
    await flushPromises();
    await flushPromises();

    const amountInput = element.shadowRoot.querySelector(".amount-input");
    amountInput.value = "4500";
    amountInput.dispatchEvent(new CustomEvent("change"));
    await flushPromises();

    element.shadowRoot.querySelector(".approve").click();
    await flushPromises();

    expect(processDecision).toHaveBeenCalledWith({
      request: expect.objectContaining({
        requestId: "a03xx0000000001",
        decision: "Approved",
        approvedAmount: 4500
      })
    });
  });

  it("requires a rejection reason before submitting a reject decision", async () => {
    processDecision.mockResolvedValue();

    const element = createElement("c-ps-mdf-review-workspace", {
      is: PsMdfReviewWorkspace
    });

    document.body.appendChild(element);

    getReviewQueue.emit([QUEUE_ROW]);
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

    textarea.value = "Missing campaign documentation.";
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
        requestId: "a03xx0000000001",
        decision: "Rejected",
        rejectionReason: "Missing campaign documentation."
      })
    });
  });

  it("renders decided requests as read-only with a stamp instead of actions", async () => {
    const element = createElement("c-ps-mdf-review-workspace", {
      is: PsMdfReviewWorkspace
    });

    document.body.appendChild(element);

    getReviewQueue.emit([
      {
        ...QUEUE_ROW,
        status: "Approved",
        approvedAmount: 4500
      }
    ]);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector(".approve")).toBeNull();
    expect(element.shadowRoot.querySelector(".reject")).toBeNull();
    expect(element.shadowRoot.querySelector(".stamp").textContent).toBe(
      "Approved"
    );
  });

  it("surfaces a decision error without clearing the selected request", async () => {
    processDecision.mockRejectedValue({
      body: { message: "Partner MDF budget exceeded." }
    });

    const element = createElement("c-ps-mdf-review-workspace", {
      is: PsMdfReviewWorkspace
    });

    document.body.appendChild(element);

    getReviewQueue.emit([QUEUE_ROW]);
    await flushPromises();
    await flushPromises();

    element.shadowRoot.querySelector(".approve").click();
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "Partner MDF budget exceeded."
    );
    expect(element.shadowRoot.querySelector(".hero-card h2").textContent).toBe(
      "Q3 Field Event"
    );
  });
});
