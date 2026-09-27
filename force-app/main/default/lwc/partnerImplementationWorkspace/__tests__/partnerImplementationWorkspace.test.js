import { createElement } from "@lwc/engine-dom";
import PartnerImplementationWorkspace from "c/partnerImplementationWorkspace";
import getImplementationSummary from "@salesforce/apex/ImplementationController.getImplementationSummary";
import getImplementationDetail from "@salesforce/apex/ImplementationController.getImplementationDetail";
import completeMilestone from "@salesforce/apex/ImplementationController.completeMilestone";

jest.mock(
  "@salesforce/apex/ImplementationController.getImplementationSummary",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/ImplementationController.getImplementationDetail",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/ImplementationController.completeMilestone",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

const SUMMARY = {
  implementationId: "a0Fxx000000001",
  dealId: "a0Bxx000000001",
  customerName: "Acme Co",
  partnerName: "Partner A",
  implementationType: "Initial Implementation",
  status: "In Progress",
  health: "Healthy",
  versionNumber: 0
};

const DETAIL = {
  summary: SUMMARY,
  milestones: [
    {
      milestoneId: "a0Gxx000000001",
      name: "Kickoff",
      milestoneType: "Kickoff",
      status: "In Progress",
      dueOn: "2026-01-01",
      versionNumber: 0
    }
  ],
  evidenceItems: [],
  issues: [],
  acceptances: []
};

describe("c-partner-implementation-workspace", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders the implementation summary and its milestones", async () => {
    const element = createElement("c-partner-implementation-workspace", {
      is: PartnerImplementationWorkspace
    });
    element.recordId = "a0Bxx000000001";
    document.body.appendChild(element);

    getImplementationSummary.emit(SUMMARY);
    await flushPromises();
    getImplementationDetail.emit(DETAIL);
    await flushPromises();

    expect(element.shadowRoot.textContent).toContain("Acme Co");
    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
    expect(element.shadowRoot.querySelector("button.accept")).not.toBeNull();
  });

  it("completes a milestone the partner owns", async () => {
    completeMilestone.mockResolvedValue();
    const element = createElement("c-partner-implementation-workspace", {
      is: PartnerImplementationWorkspace
    });
    element.recordId = "a0Bxx000000001";
    document.body.appendChild(element);

    getImplementationSummary.emit(SUMMARY);
    await flushPromises();
    getImplementationDetail.emit(DETAIL);
    await flushPromises();

    element.shadowRoot.querySelector("button.accept").click();
    await flushPromises();

    expect(completeMilestone).toHaveBeenCalledWith({
      command: {
        milestoneId: "a0Gxx000000001",
        expectedVersion: 0
      }
    });
  });

  it("shows an empty state when the deal has no implementation yet", async () => {
    const element = createElement("c-partner-implementation-workspace", {
      is: PartnerImplementationWorkspace
    });
    element.recordId = "a0Bxx000000001";
    document.body.appendChild(element);

    getImplementationSummary.emit(null);
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-empty-state")).not.toBeNull();
  });

  it("shows an error panel when the summary wire fails", async () => {
    const element = createElement("c-partner-implementation-workspace", {
      is: PartnerImplementationWorkspace
    });
    element.recordId = "a0Bxx000000001";
    document.body.appendChild(element);

    getImplementationSummary.error({
      message: "This deal is not accessible."
    });
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "This deal is not accessible."
    );
  });
});
