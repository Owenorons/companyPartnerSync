import { createElement } from "@lwc/engine-dom";
import PsApprovalWorkspace from "c/psApprovalWorkspace";
import getMyPendingSteps from "@salesforce/apex/ApprovalController.getMyPendingSteps";
import getStepDetail from "@salesforce/apex/ApprovalController.getStepDetail";
import decide from "@salesforce/apex/ApprovalController.decide";

jest.mock(
  "@salesforce/apex/ApprovalController.getMyPendingSteps",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/ApprovalController.getStepDetail",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/ApprovalController.decide",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-ps-approval-workspace", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders the pending steps queue and loads the first step's detail", async () => {
    getStepDetail.mockResolvedValue({
      approvalId: "a03xx0000000001",
      objectName: "Deal_Registration__c",
      targetRecordId: "a02xx0000000001",
      targetLabel: "DR-001 — Acme",
      stepKey: "Deal_Channel_Manager",
      sequence: 1,
      status: "Pending",
      targetAmount: 100000,
      authorityLimit: 500000,
      expectedVersion: 0,
      canDecide: true
    });

    const element = createElement("c-ps-approval-workspace", {
      is: PsApprovalWorkspace
    });
    document.body.appendChild(element);

    getMyPendingSteps.emit([
      {
        approvalId: "a03xx0000000001",
        objectName: "Deal_Registration__c",
        targetRecordId: "a02xx0000000001",
        targetLabel: "DR-001 — Acme",
        stepKey: "Deal_Channel_Manager",
        sequence: 1,
        status: "Pending",
        targetAmount: 100000
      }
    ]);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector(".queue-row h3").textContent).toBe(
      "DR-001 — Acme"
    );
    expect(getStepDetail).toHaveBeenCalledWith({
      approvalId: "a03xx0000000001"
    });
    expect(element.shadowRoot.querySelector(".approve")).not.toBeNull();
  });

  it("approves a pending step and reloads the queue", async () => {
    getStepDetail.mockResolvedValue({
      approvalId: "a03xx0000000002",
      objectName: "Deal_Registration__c",
      targetRecordId: "a02xx0000000002",
      targetLabel: "DR-002 — Beta",
      stepKey: "Deal_Channel_Manager",
      status: "Pending",
      expectedVersion: 2,
      canDecide: true
    });
    decide.mockResolvedValue();

    const element = createElement("c-ps-approval-workspace", {
      is: PsApprovalWorkspace
    });
    document.body.appendChild(element);

    getMyPendingSteps.emit([
      {
        approvalId: "a03xx0000000002",
        objectName: "Deal_Registration__c",
        targetRecordId: "a02xx0000000002",
        targetLabel: "DR-002 — Beta",
        stepKey: "Deal_Channel_Manager",
        status: "Pending"
      }
    ]);
    await flushPromises();
    await flushPromises();

    element.shadowRoot.querySelector(".approve").click();
    await flushPromises();
    await flushPromises();

    expect(decide).toHaveBeenCalledWith({
      request: {
        approvalId: "a03xx0000000002",
        decision: "Approved",
        expectedVersion: 2
      }
    });
  });

  it("requires a reason before submitting a reject decision", async () => {
    getStepDetail.mockResolvedValue({
      approvalId: "a03xx0000000003",
      objectName: "Deal_Registration__c",
      targetRecordId: "a02xx0000000003",
      targetLabel: "DR-003 — Gamma",
      stepKey: "Deal_Channel_Manager",
      status: "Pending",
      expectedVersion: 0,
      canDecide: true
    });
    decide.mockResolvedValue();

    const element = createElement("c-ps-approval-workspace", {
      is: PsApprovalWorkspace
    });
    document.body.appendChild(element);

    getMyPendingSteps.emit([
      {
        approvalId: "a03xx0000000003",
        objectName: "Deal_Registration__c",
        targetRecordId: "a02xx0000000003",
        targetLabel: "DR-003 — Gamma",
        stepKey: "Deal_Channel_Manager",
        status: "Pending"
      }
    ]);
    await flushPromises();
    await flushPromises();

    element.shadowRoot.querySelector(".reject").click();
    await flushPromises();

    let confirmButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Confirm");
    expect(confirmButton.disabled).toBe(true);

    const textarea = element.shadowRoot.querySelector("lightning-textarea");
    textarea.value = "Amount exceeds delegated authority.";
    textarea.dispatchEvent(new CustomEvent("change"));
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
        approvalId: "a03xx0000000003",
        decision: "Rejected",
        expectedVersion: 0,
        reason: "Amount exceeds delegated authority."
      }
    });
  });

  it("hides decision actions and shows a permission notice when the step can't be decided", async () => {
    getStepDetail.mockResolvedValue({
      approvalId: "a03xx0000000004",
      objectName: "MDF_Request__c",
      targetRecordId: "a02xx0000000004",
      targetLabel: "MDF-004 — Delta",
      stepKey: "MDF_Reviewer",
      status: "Pending",
      expectedVersion: 0,
      canDecide: false
    });

    const element = createElement("c-ps-approval-workspace", {
      is: PsApprovalWorkspace
    });
    document.body.appendChild(element);

    getMyPendingSteps.emit([
      {
        approvalId: "a03xx0000000004",
        objectName: "MDF_Request__c",
        targetRecordId: "a02xx0000000004",
        targetLabel: "MDF-004 — Delta",
        stepKey: "MDF_Reviewer",
        status: "Pending"
      }
    ]);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector(".approve")).toBeNull();
    expect(
      element.shadowRoot.querySelector(".decision-state").textContent
    ).toContain("You do not have permission to decide this step.");
  });

  it("shows an empty state when there are no pending steps", async () => {
    const element = createElement("c-ps-approval-workspace", {
      is: PsApprovalWorkspace
    });
    document.body.appendChild(element);

    getMyPendingSteps.emit([]);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-empty-state")).not.toBeNull();
    expect(getStepDetail).not.toHaveBeenCalled();
  });
});
