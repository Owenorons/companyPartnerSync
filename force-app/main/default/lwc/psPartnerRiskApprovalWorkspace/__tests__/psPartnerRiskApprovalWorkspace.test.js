import { createElement } from "@lwc/engine-dom";
import PsPartnerRiskApprovalWorkspace from "c/psPartnerRiskApprovalWorkspace";
import getApprovalQueue from "@salesforce/apex/PartnerRiskApprovalController.getApprovalQueue";
import decideStep from "@salesforce/apex/PartnerRiskApprovalController.decideStep";

jest.mock(
  "@salesforce/apex/PartnerRiskApprovalController.getApprovalQueue",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PartnerRiskApprovalController.decideStep",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

const QUEUE_ROW = {
  stepId: "a03xx0000000001",
  planId: "a04xx0000000001",
  onboardingId: "a05xx0000000001",
  partnerName: "North Partner",
  dimension: "Compliance",
  sequence: 1,
  status: "Pending",
  assignedToId: null,
  assignedToName: null,
  decisionByName: null,
  decisionOn: null,
  decisionReason: null,
  canDecide: true
};

describe("c-ps-partner-risk-approval-workspace", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders queue rows and selects the first step", async () => {
    const element = createElement("c-ps-partner-risk-approval-workspace", {
      is: PsPartnerRiskApprovalWorkspace
    });

    document.body.appendChild(element);

    getApprovalQueue.emit([QUEUE_ROW]);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector(".queue-row h3").textContent).toBe(
      "North Partner"
    );
    expect(element.shadowRoot.querySelector(".hero-card h2").textContent).toBe(
      "North Partner"
    );
  });

  it("submits a decision for the selected step and refreshes the queue", async () => {
    decideStep.mockResolvedValue();

    const element = createElement("c-ps-partner-risk-approval-workspace", {
      is: PsPartnerRiskApprovalWorkspace
    });

    document.body.appendChild(element);

    getApprovalQueue.emit([QUEUE_ROW]);
    await flushPromises();
    await flushPromises();

    const textarea = element.shadowRoot.querySelector("lightning-textarea");
    textarea.value = "Meets programme requirements.";
    textarea.dispatchEvent(new CustomEvent("change"));
    await flushPromises();

    const submitButton = element.shadowRoot.querySelector("lightning-button");
    submitButton.click();
    await flushPromises();
    await flushPromises();

    expect(decideStep).toHaveBeenCalledWith({
      request: {
        stepId: "a03xx0000000001",
        decision: "Approved",
        reason: "Meets programme requirements."
      }
    });
  });

  it("shows an assignment message when the step cannot be decided by the current user", async () => {
    const element = createElement("c-ps-partner-risk-approval-workspace", {
      is: PsPartnerRiskApprovalWorkspace
    });

    document.body.appendChild(element);

    getApprovalQueue.emit([{ ...QUEUE_ROW, canDecide: false }]);
    await flushPromises();
    await flushPromises();

    expect(
      element.shadowRoot.querySelector(".decision-state").textContent
    ).toContain("assigned to another reviewer");
    // Only the sidebar's status filter combobox remains; the decision
    // combobox is hidden when the step cannot be decided.
    expect(
      element.shadowRoot.querySelectorAll("lightning-combobox").length
    ).toBe(1);
  });
});
