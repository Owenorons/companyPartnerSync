import { createElement } from "@lwc/engine-dom";
import PsDealReviewStepWorkspace from "c/psDealReviewStepWorkspace";
import getMyPendingSteps from "@salesforce/apex/DealReviewStepController.getMyPendingSteps";
import getStepDetail from "@salesforce/apex/DealReviewStepController.getStepDetail";
import decide from "@salesforce/apex/DealReviewStepController.decide";

jest.mock(
  "@salesforce/apex/DealReviewStepController.getMyPendingSteps",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/DealReviewStepController.getStepDetail",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/DealReviewStepController.decide",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-ps-deal-review-step-workspace", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders the pending steps queue and loads the first step's detail", async () => {
    getStepDetail.mockResolvedValue({
      reviewId: "a05xx0000000001",
      dealId: "a02xx0000000001",
      dealLabel: "DR-001 — Acme",
      reviewKey: "Channel_Review",
      reviewType: "Channel",
      sequence: 1,
      status: "Ready",
      blocking: true,
      expectedVersion: 0,
      canDecide: true,
      canReassign: false
    });

    const element = createElement("c-ps-deal-review-step-workspace", {
      is: PsDealReviewStepWorkspace
    });
    document.body.appendChild(element);

    getMyPendingSteps.emit([
      {
        reviewId: "a05xx0000000001",
        dealId: "a02xx0000000001",
        dealLabel: "DR-001 — Acme",
        reviewKey: "Channel_Review",
        reviewType: "Channel",
        sequence: 1,
        status: "Ready",
        blocking: true
      }
    ]);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector(".queue-row h3").textContent).toBe(
      "DR-001 — Acme"
    );
    expect(getStepDetail).toHaveBeenCalledWith({
      reviewId: "a05xx0000000001"
    });

    const actionButtons = element.shadowRoot.querySelectorAll(".action-button");
    const labels = Array.from(actionButtons).map((btn) =>
      btn.textContent.trim()
    );
    expect(labels).toContain("Start");
  });

  it("submits a no-dialog action like Start directly", async () => {
    getStepDetail.mockResolvedValue({
      reviewId: "a05xx0000000002",
      dealId: "a02xx0000000002",
      dealLabel: "DR-002 — Beta",
      reviewKey: "Channel_Review",
      reviewType: "Channel",
      status: "Ready",
      expectedVersion: 2,
      canDecide: true,
      canReassign: false
    });
    decide.mockResolvedValue();

    const element = createElement("c-ps-deal-review-step-workspace", {
      is: PsDealReviewStepWorkspace
    });
    document.body.appendChild(element);

    getMyPendingSteps.emit([
      {
        reviewId: "a05xx0000000002",
        dealId: "a02xx0000000002",
        dealLabel: "DR-002 — Beta",
        reviewKey: "Channel_Review",
        reviewType: "Channel",
        status: "Ready"
      }
    ]);
    await flushPromises();
    await flushPromises();

    const startButton = Array.from(
      element.shadowRoot.querySelectorAll(".action-button")
    ).find((btn) => btn.dataset.action === "Start");
    startButton.click();
    await flushPromises();
    await flushPromises();

    expect(decide).toHaveBeenCalledWith({
      request: {
        reviewId: "a05xx0000000002",
        action: "Start",
        expectedVersion: 2
      }
    });
  });

  it("requires an outcome before submitting a Complete action", async () => {
    getStepDetail.mockResolvedValue({
      reviewId: "a05xx0000000003",
      dealId: "a02xx0000000003",
      dealLabel: "DR-003 — Gamma",
      reviewKey: "Channel_Review",
      reviewType: "Channel",
      status: "In Progress",
      expectedVersion: 0,
      canDecide: true,
      canReassign: false
    });
    decide.mockResolvedValue();

    const element = createElement("c-ps-deal-review-step-workspace", {
      is: PsDealReviewStepWorkspace
    });
    document.body.appendChild(element);

    getMyPendingSteps.emit([
      {
        reviewId: "a05xx0000000003",
        dealId: "a02xx0000000003",
        dealLabel: "DR-003 — Gamma",
        reviewKey: "Channel_Review",
        reviewType: "Channel",
        status: "In Progress"
      }
    ]);
    await flushPromises();
    await flushPromises();

    const completeButton = Array.from(
      element.shadowRoot.querySelectorAll(".action-button")
    ).find((btn) => btn.dataset.action === "Complete");
    completeButton.click();
    await flushPromises();

    let confirmButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Confirm");
    expect(confirmButton.disabled).toBe(true);

    const outcomeInput = element.shadowRoot.querySelector("lightning-input");
    outcomeInput.value = "Approved";
    outcomeInput.dispatchEvent(new CustomEvent("change"));
    await flushPromises();

    confirmButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Confirm");
    expect(confirmButton.disabled).toBe(false);

    confirmButton.click();
    await flushPromises();
    await flushPromises();

    expect(decide).toHaveBeenCalledWith({
      request: {
        reviewId: "a05xx0000000003",
        action: "Complete",
        expectedVersion: 0,
        outcome: "Approved"
      }
    });
  });

  it("offers Reassign for a Routing Failed step even without decide authority", async () => {
    getStepDetail.mockResolvedValue({
      reviewId: "a05xx0000000004",
      dealId: "a02xx0000000004",
      dealLabel: "DR-004 — Delta",
      reviewKey: "Commercial_Review",
      reviewType: "Commercial",
      status: "Routing Failed",
      expectedVersion: 0,
      canDecide: false,
      canReassign: true
    });
    decide.mockResolvedValue();

    const element = createElement("c-ps-deal-review-step-workspace", {
      is: PsDealReviewStepWorkspace
    });
    document.body.appendChild(element);

    getMyPendingSteps.emit([
      {
        reviewId: "a05xx0000000004",
        dealId: "a02xx0000000004",
        dealLabel: "DR-004 — Delta",
        reviewKey: "Commercial_Review",
        reviewType: "Commercial",
        status: "Routing Failed"
      }
    ]);
    await flushPromises();
    await flushPromises();

    const reassignButton = Array.from(
      element.shadowRoot.querySelectorAll(".action-button")
    ).find((btn) => btn.dataset.action === "Reassign");
    expect(reassignButton).not.toBeNull();

    reassignButton.click();
    await flushPromises();

    const picker = element.shadowRoot.querySelector("lightning-record-picker");
    picker.dispatchEvent(
      new CustomEvent("change", {
        detail: { recordId: "005xx0000000001" }
      })
    );
    await flushPromises();

    const confirmButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Confirm");
    expect(confirmButton.disabled).toBe(false);

    confirmButton.click();
    await flushPromises();
    await flushPromises();

    expect(decide).toHaveBeenCalledWith({
      request: {
        reviewId: "a05xx0000000004",
        action: "Reassign",
        expectedVersion: 0,
        assigneeId: "005xx0000000001"
      }
    });
  });

  it("shows a permission notice when the step can't be worked", async () => {
    getStepDetail.mockResolvedValue({
      reviewId: "a05xx0000000005",
      dealId: "a02xx0000000005",
      dealLabel: "DR-005 — Epsilon",
      reviewKey: "Channel_Review",
      reviewType: "Channel",
      status: "Ready",
      expectedVersion: 0,
      canDecide: false,
      canReassign: false
    });

    const element = createElement("c-ps-deal-review-step-workspace", {
      is: PsDealReviewStepWorkspace
    });
    document.body.appendChild(element);

    getMyPendingSteps.emit([
      {
        reviewId: "a05xx0000000005",
        dealId: "a02xx0000000005",
        dealLabel: "DR-005 — Epsilon",
        reviewKey: "Channel_Review",
        reviewType: "Channel",
        status: "Ready"
      }
    ]);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector(".action-button")).toBeNull();
    expect(
      element.shadowRoot.querySelector(".decision-state").textContent
    ).toContain("You do not have permission to act on this review step.");
  });

  it("shows an empty state when there are no pending steps", async () => {
    const element = createElement("c-ps-deal-review-step-workspace", {
      is: PsDealReviewStepWorkspace
    });
    document.body.appendChild(element);

    getMyPendingSteps.emit([]);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-empty-state")).not.toBeNull();
    expect(getStepDetail).not.toHaveBeenCalled();
  });
});
