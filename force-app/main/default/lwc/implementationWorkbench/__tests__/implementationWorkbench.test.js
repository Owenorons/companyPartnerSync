import { createElement } from "@lwc/engine-dom";
import ImplementationWorkbench from "c/implementationWorkbench";
import getPendingHandoff from "@salesforce/apex/ImplementationController.getPendingHandoff";
import getReadyToStart from "@salesforce/apex/ImplementationController.getReadyToStart";
import getInProgress from "@salesforce/apex/ImplementationController.getInProgress";
import getAtRiskOrBlocked from "@salesforce/apex/ImplementationController.getAtRiskOrBlocked";
import getAwaitingAcceptance from "@salesforce/apex/ImplementationController.getAwaitingAcceptance";
import getOverdue from "@salesforce/apex/ImplementationController.getOverdue";
import getCompleted from "@salesforce/apex/ImplementationController.getCompleted";

function mockWireAdapter() {
  const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
  return { default: createApexTestWireAdapter(jest.fn()) };
}

jest.mock(
  "@salesforce/apex/ImplementationController.getPendingHandoff",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/ImplementationController.getReadyToStart",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/ImplementationController.getInProgress",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/ImplementationController.getAtRiskOrBlocked",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/ImplementationController.getAwaitingAcceptance",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/ImplementationController.getOverdue",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/ImplementationController.getCompleted",
  () => mockWireAdapter(),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

function selectTab(element, tabName) {
  element.shadowRoot.querySelector(`button[data-tab="${tabName}"]`).click();
}

describe("c-implementation-workbench", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders implementations pending handoff by default", async () => {
    const element = createElement("c-implementation-workbench", {
      is: ImplementationWorkbench
    });
    document.body.appendChild(element);

    getPendingHandoff.emit([
      {
        implementationId: "a0Fxx000000001",
        customerName: "Acme Co",
        partnerName: "Partner A",
        status: "Not Started",
        health: "Healthy"
      }
    ]);
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("renders implementations ready to start on that tab", async () => {
    const element = createElement("c-implementation-workbench", {
      is: ImplementationWorkbench
    });
    document.body.appendChild(element);

    getReadyToStart.emit([
      {
        implementationId: "a0Fxx000000002",
        customerName: "Beta Co",
        partnerName: "Partner B",
        status: "Not Started",
        health: "Healthy"
      }
    ]);
    await flushPromises();

    selectTab(element, "readyToStart");
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("renders in-progress implementations on that tab", async () => {
    const element = createElement("c-implementation-workbench", {
      is: ImplementationWorkbench
    });
    document.body.appendChild(element);

    getInProgress.emit([
      {
        implementationId: "a0Fxx000000003",
        customerName: "Gamma Co",
        partnerName: "Partner C",
        status: "In Progress",
        health: "Healthy"
      }
    ]);
    await flushPromises();

    selectTab(element, "inProgress");
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("renders at-risk or blocked implementations on that tab", async () => {
    const element = createElement("c-implementation-workbench", {
      is: ImplementationWorkbench
    });
    document.body.appendChild(element);

    getAtRiskOrBlocked.emit([
      {
        implementationId: "a0Fxx000000004",
        customerName: "Delta Co",
        partnerName: "Partner D",
        status: "In Progress",
        health: "Blocked"
      }
    ]);
    await flushPromises();

    selectTab(element, "atRiskBlocked");
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("renders implementations awaiting acceptance on that tab", async () => {
    const element = createElement("c-implementation-workbench", {
      is: ImplementationWorkbench
    });
    document.body.appendChild(element);

    getAwaitingAcceptance.emit([
      {
        implementationId: "a0Fxx000000005",
        customerName: "Epsilon Co",
        partnerName: "Partner E",
        status: "Pending Customer Acceptance",
        health: "Healthy"
      }
    ]);
    await flushPromises();

    selectTab(element, "awaitingAcceptance");
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("renders overdue implementations on that tab", async () => {
    const element = createElement("c-implementation-workbench", {
      is: ImplementationWorkbench
    });
    document.body.appendChild(element);

    getOverdue.emit([
      {
        implementationId: "a0Fxx000000006",
        customerName: "Zeta Co",
        partnerName: "Partner F",
        status: "In Progress",
        health: "Overdue"
      }
    ]);
    await flushPromises();

    selectTab(element, "overdue");
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("renders completed implementations on that tab", async () => {
    const element = createElement("c-implementation-workbench", {
      is: ImplementationWorkbench
    });
    document.body.appendChild(element);

    getCompleted.emit([
      {
        implementationId: "a0Fxx000000007",
        customerName: "Eta Co",
        partnerName: "Partner G",
        status: "Completed",
        health: "Healthy"
      }
    ]);
    await flushPromises();

    selectTab(element, "completed");
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("shows an error panel when a wire fails", async () => {
    const element = createElement("c-implementation-workbench", {
      is: ImplementationWorkbench
    });
    document.body.appendChild(element);

    getPendingHandoff.error({
      body: { message: "Workbench access denied." }
    });
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "Unable to load implementations pending handoff."
    );
  });
});
