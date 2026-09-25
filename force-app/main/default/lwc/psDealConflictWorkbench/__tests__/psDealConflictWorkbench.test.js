import { createElement } from "@lwc/engine-dom";
import PsDealConflictWorkbench from "c/psDealConflictWorkbench";
import getPendingConflicts from "@salesforce/apex/DealConflictCommandController.getPendingConflicts";
import getConflictDetail from "@salesforce/apex/DealConflictCommandController.getConflictDetail";
import executeCommand from "@salesforce/apex/DealConflictCommandController.executeCommand";

jest.mock(
  "@salesforce/apex/DealConflictCommandController.getPendingConflicts",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/DealConflictCommandController.getConflictDetail",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/DealConflictCommandController.executeCommand",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-ps-deal-conflict-workbench", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders the pending conflict queue and loads the first finding's detail", async () => {
    getConflictDetail.mockResolvedValue({
      conflictId: "a06xx0000000001",
      dealId: "a02xx0000000001",
      dealLabel: "DR-001 — Acme",
      type: "Existing Registration",
      subtype: "Same Customer Account",
      severity: "High",
      confidence: 90,
      matchScore: 100,
      blocking: true,
      status: "Open",
      expectedVersion: 0
    });

    const element = createElement("c-ps-deal-conflict-workbench", {
      is: PsDealConflictWorkbench
    });
    document.body.appendChild(element);

    getPendingConflicts.emit([
      {
        conflictId: "a06xx0000000001",
        dealId: "a02xx0000000001",
        dealLabel: "DR-001 — Acme",
        type: "Existing Registration",
        severity: "High",
        status: "Open"
      }
    ]);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector(".queue-row h3").textContent).toBe(
      "DR-001 — Acme"
    );
    expect(getConflictDetail).toHaveBeenCalledWith({
      conflictId: "a06xx0000000001"
    });

    const actionButtons = element.shadowRoot.querySelectorAll(".action-button");
    const labels = Array.from(actionButtons).map((btn) =>
      btn.textContent.trim()
    );
    expect(labels).toContain("Assign");
    expect(labels).toContain("Reanalyse Deal");
  });

  it("submits a no-dialog action like Start Investigation directly", async () => {
    getConflictDetail.mockResolvedValue({
      conflictId: "a06xx0000000002",
      dealId: "a02xx0000000002",
      dealLabel: "DR-002 — Beta",
      type: "Existing Registration",
      severity: "High",
      status: "Open",
      expectedVersion: 1
    });
    executeCommand.mockResolvedValue({ completed: true });

    const element = createElement("c-ps-deal-conflict-workbench", {
      is: PsDealConflictWorkbench
    });
    document.body.appendChild(element);

    getPendingConflicts.emit([
      {
        conflictId: "a06xx0000000002",
        dealId: "a02xx0000000002",
        dealLabel: "DR-002 — Beta",
        type: "Existing Registration",
        severity: "High",
        status: "Open"
      }
    ]);
    await flushPromises();
    await flushPromises();

    const startButton = Array.from(
      element.shadowRoot.querySelectorAll(".action-button")
    ).find((btn) => btn.dataset.action === "Start Investigation");
    startButton.click();
    await flushPromises();
    await flushPromises();

    expect(executeCommand).toHaveBeenCalledTimes(1);
    const call = executeCommand.mock.calls[0][0];
    const request = JSON.parse(call.requestJson);
    expect(request.conflictId).toBe("a06xx0000000002");
    expect(request.action).toBe("Start Investigation");
    expect(request.expectedVersion).toBe(1);
  });

  it("requires a reason before submitting Resolve Conflict", async () => {
    getConflictDetail.mockResolvedValue({
      conflictId: "a06xx0000000003",
      dealId: "a02xx0000000003",
      dealLabel: "DR-003 — Gamma",
      type: "Existing Registration",
      severity: "High",
      status: "Confirmed",
      expectedVersion: 0
    });
    executeCommand.mockResolvedValue({ completed: true });

    const element = createElement("c-ps-deal-conflict-workbench", {
      is: PsDealConflictWorkbench
    });
    document.body.appendChild(element);

    getPendingConflicts.emit([
      {
        conflictId: "a06xx0000000003",
        dealId: "a02xx0000000003",
        dealLabel: "DR-003 — Gamma",
        type: "Existing Registration",
        severity: "High",
        status: "Confirmed"
      }
    ]);
    await flushPromises();
    await flushPromises();

    const resolveButton = Array.from(
      element.shadowRoot.querySelectorAll(".action-button")
    ).find((btn) => btn.dataset.action === "Resolve Conflict");
    resolveButton.click();
    await flushPromises();

    let confirmButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Confirm");
    expect(confirmButton.disabled).toBe(true);

    const textarea = element.shadowRoot.querySelector("lightning-textarea");
    textarea.value = "Both parties agreed on ownership.";
    textarea.dispatchEvent(new CustomEvent("change"));
    await flushPromises();

    confirmButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Confirm");
    expect(confirmButton.disabled).toBe(false);

    confirmButton.click();
    await flushPromises();
    await flushPromises();

    expect(executeCommand).toHaveBeenCalledTimes(1);
    const request = JSON.parse(executeCommand.mock.calls[0][0].requestJson);
    expect(request.action).toBe("Resolve Conflict");
    expect(request.reason).toBe("Both parties agreed on ownership.");
  });

  it("requires all four fields before submitting Waive Conflict", async () => {
    getConflictDetail.mockResolvedValue({
      conflictId: "a06xx0000000004",
      dealId: "a02xx0000000004",
      dealLabel: "DR-004 — Delta",
      type: "Existing Registration",
      severity: "Critical",
      status: "Confirmed",
      expectedVersion: 0
    });

    const element = createElement("c-ps-deal-conflict-workbench", {
      is: PsDealConflictWorkbench
    });
    document.body.appendChild(element);

    getPendingConflicts.emit([
      {
        conflictId: "a06xx0000000004",
        dealId: "a02xx0000000004",
        dealLabel: "DR-004 — Delta",
        type: "Existing Registration",
        severity: "Critical",
        status: "Confirmed"
      }
    ]);
    await flushPromises();
    await flushPromises();

    const waiveButton = Array.from(
      element.shadowRoot.querySelectorAll(".action-button")
    ).find((btn) => btn.dataset.action === "Waive Conflict");
    waiveButton.click();
    await flushPromises();

    const confirmButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Confirm");
    expect(confirmButton.disabled).toBe(true);

    const textareas = element.shadowRoot.querySelectorAll("lightning-textarea");
    textareas[0].value = "Executive exception";
    textareas[0].dispatchEvent(new CustomEvent("change"));
    textareas[1].value = "Signed exception approval";
    textareas[1].dispatchEvent(new CustomEvent("change"));
    textareas[2].value = "Review again in 30 days";
    textareas[2].dispatchEvent(new CustomEvent("change"));
    await flushPromises();

    expect(confirmButton.disabled).toBe(true);

    const dateInput = element.shadowRoot.querySelector("lightning-input");
    dateInput.value = "2026-12-31T00:00";
    dateInput.dispatchEvent(new CustomEvent("change"));
    await flushPromises();

    expect(confirmButton.disabled).toBe(false);
  });

  it("shows an empty state when there are no pending conflicts", async () => {
    const element = createElement("c-ps-deal-conflict-workbench", {
      is: PsDealConflictWorkbench
    });
    document.body.appendChild(element);

    getPendingConflicts.emit([]);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-empty-state")).not.toBeNull();
    expect(getConflictDetail).not.toHaveBeenCalled();
  });
});
