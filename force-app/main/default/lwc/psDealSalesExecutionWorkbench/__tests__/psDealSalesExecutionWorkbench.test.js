import { createElement } from "@lwc/engine-dom";
import PsDealSalesExecutionWorkbench from "c/psDealSalesExecutionWorkbench";
import getOpportunityPendingLink from "@salesforce/apex/DealOpportunityController.getOpportunityPendingLink";
import getReapprovalRequired from "@salesforce/apex/DealOpportunityController.getReapprovalRequired";
import getOrphanedRelationships from "@salesforce/apex/DealOpportunityController.getOrphanedRelationships";
import getRecentlyClosed from "@salesforce/apex/DealOpportunityController.getRecentlyClosed";

function mockWireAdapter() {
  const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
  return { default: createApexTestWireAdapter(jest.fn()) };
}

jest.mock(
  "@salesforce/apex/DealOpportunityController.getOpportunityPendingLink",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/DealOpportunityController.getReapprovalRequired",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/DealOpportunityController.getOrphanedRelationships",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/DealOpportunityController.getRecentlyClosed",
  () => mockWireAdapter(),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

function selectTab(element, tabName) {
  element.shadowRoot.querySelector(`button[data-tab="${tabName}"]`).click();
}

describe("c-ps-deal-sales-execution-workbench", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders deals pending an opportunity link by default", async () => {
    const element = createElement("c-ps-deal-sales-execution-workbench", {
      is: PsDealSalesExecutionWorkbench
    });
    document.body.appendChild(element);

    getOpportunityPendingLink.emit([
      {
        dealId: "a0Dxx000000001",
        customerName: "Acme Co",
        partnerName: "Partner A",
        status: "Approved",
        stage: "Qualification"
      }
    ]);
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("renders reapproval required deals on the reapproval tab", async () => {
    const element = createElement("c-ps-deal-sales-execution-workbench", {
      is: PsDealSalesExecutionWorkbench
    });
    document.body.appendChild(element);

    getReapprovalRequired.emit([
      {
        dealId: "a0Dxx000000002",
        customerName: "Beta Co",
        partnerName: "Partner B",
        status: "Under Review",
        stage: "Proposal"
      }
    ]);
    await flushPromises();

    selectTab(element, "reapproval");
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("renders orphaned relationships on the orphaned tab", async () => {
    const element = createElement("c-ps-deal-sales-execution-workbench", {
      is: PsDealSalesExecutionWorkbench
    });
    document.body.appendChild(element);

    getOrphanedRelationships.emit([
      {
        dealId: "a0Dxx000000003",
        customerName: "Gamma Co",
        partnerName: "Partner C",
        status: "Approved",
        stage: "Negotiation"
      }
    ]);
    await flushPromises();

    selectTab(element, "orphaned");
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("renders recently closed deals on the recently closed tab", async () => {
    const element = createElement("c-ps-deal-sales-execution-workbench", {
      is: PsDealSalesExecutionWorkbench
    });
    document.body.appendChild(element);

    getRecentlyClosed.emit([
      {
        dealId: "a0Dxx000000004",
        customerName: "Delta Co",
        partnerName: "Partner D",
        status: "Approved",
        stage: "Closed Won"
      }
    ]);
    await flushPromises();

    selectTab(element, "recentlyClosed");
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("shows an error panel when a wire fails", async () => {
    const element = createElement("c-ps-deal-sales-execution-workbench", {
      is: PsDealSalesExecutionWorkbench
    });
    document.body.appendChild(element);

    getOpportunityPendingLink.error({
      body: { message: "Workbench access denied." }
    });
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "Unable to load deals pending an opportunity link."
    );
  });
});
