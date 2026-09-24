import { createElement } from "@lwc/engine-dom";
import PsAiGovernanceConsole from "c/psAiGovernanceConsole";
import getPendingReview from "@salesforce/apex/AIInsightController.getPendingReview";
import getInsightTypes from "@salesforce/apex/AIInsightController.getInsightTypes";
import reviewInsight from "@salesforce/apex/AIInsightController.reviewInsight";
import enqueueInsight from "@salesforce/apex/AIInsightController.enqueueInsight";
import getPendingRequests from "@salesforce/apex/AIInsightController.getPendingRequests";
import actionRequest from "@salesforce/apex/AIInsightController.actionRequest";
import dismissRequest from "@salesforce/apex/AIInsightController.dismissRequest";

jest.mock(
  "@salesforce/apex/AIInsightController.getPendingReview",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/AIInsightController.getInsightTypes",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/AIInsightController.reviewInsight",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/AIInsightController.enqueueInsight",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/AIInsightController.getPendingRequests",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/AIInsightController.actionRequest",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/AIInsightController.dismissRequest",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

const PENDING_INSIGHT = {
  insightId: "a0X000000000001",
  partnerAccountId: "001000000000001",
  partnerName: "Acme Partner",
  insightType: "Partner Health Score",
  provider: "OpenAI",
  confidence: 82,
  recommendation: "Schedule a check-in.",
  summary: "Engagement has declined over the last quarter.",
  status: "Draft",
  generatedOn: "2026-09-01T00:00:00.000Z"
};

const INSIGHT_TYPES = [
  { developerName: "PartnerHealthScore", label: "Partner Health Score" }
];

const PENDING_REQUEST = {
  requestId: "a0Y000000000001",
  partnerAccountId: "001000000000001",
  partnerName: "Acme Partner",
  insightType: "PartnerHealthScore",
  insightTypeLabel: "Partner Health Score",
  notes: "Struggling to close their pipeline this quarter.",
  status: "New",
  requestedOn: "2026-09-01T00:00:00.000Z"
};

describe("c-ps-ai-governance-console", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    jest.useRealTimers();
  });

  it("renders insights awaiting review", async () => {
    const element = createElement("c-ps-ai-governance-console", {
      is: PsAiGovernanceConsole
    });
    document.body.appendChild(element);

    getInsightTypes.emit(INSIGHT_TYPES);
    getPendingRequests.emit([]);
    getPendingReview.emit([PENDING_INSIGHT]);
    await flushPromises();

    expect(
      element.shadowRoot.querySelector(".review-list article h2").textContent
    ).toBe("Partner Health Score");
  });

  it("accepts an insight with the entered recommendation", async () => {
    reviewInsight.mockResolvedValue();

    const element = createElement("c-ps-ai-governance-console", {
      is: PsAiGovernanceConsole
    });
    document.body.appendChild(element);

    getInsightTypes.emit(INSIGHT_TYPES);
    getPendingRequests.emit([]);
    getPendingReview.emit([PENDING_INSIGHT]);
    await flushPromises();

    const acceptButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Accept and publish");
    acceptButton.click();
    await flushPromises();

    expect(reviewInsight).toHaveBeenCalledWith({
      insightId: PENDING_INSIGHT.insightId,
      decision: "Accepted",
      recommendation: PENDING_INSIGHT.recommendation
    });
  });

  it("disables Generate until a partner and insight type are selected", async () => {
    const element = createElement("c-ps-ai-governance-console", {
      is: PsAiGovernanceConsole
    });
    document.body.appendChild(element);

    getInsightTypes.emit(INSIGHT_TYPES);
    getPendingRequests.emit([]);
    getPendingReview.emit([]);
    await flushPromises();

    const generateButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Generate");
    expect(generateButton.disabled).toBe(true);

    element.shadowRoot.querySelector("lightning-record-picker").dispatchEvent(
      new CustomEvent("recordselect", {
        detail: { recordId: "001000000000001" }
      })
    );
    element.shadowRoot
      .querySelector("lightning-combobox")
      .dispatchEvent(
        new CustomEvent("change", { detail: { value: "PartnerHealthScore" } })
      );
    await flushPromises();

    expect(generateButton.disabled).toBe(false);
  });

  it("enqueues generation and reports success once the insight appears", async () => {
    jest.useFakeTimers();
    enqueueInsight.mockResolvedValue("707000000000001");

    const element = createElement("c-ps-ai-governance-console", {
      is: PsAiGovernanceConsole
    });
    document.body.appendChild(element);

    getInsightTypes.emit(INSIGHT_TYPES);
    getPendingRequests.emit([]);
    getPendingReview.emit([]);
    await flushPromises();

    element.shadowRoot.querySelector("lightning-record-picker").dispatchEvent(
      new CustomEvent("recordselect", {
        detail: { recordId: "001000000000001" }
      })
    );
    element.shadowRoot
      .querySelector("lightning-combobox")
      .dispatchEvent(
        new CustomEvent("change", { detail: { value: "PartnerHealthScore" } })
      );
    await flushPromises();

    const generateButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Generate");
    generateButton.click();
    await flushPromises();

    expect(enqueueInsight).toHaveBeenCalledWith({
      request: {
        partnerAccountId: "001000000000001",
        insightType: "PartnerHealthScore",
        contextData: null
      }
    });

    // The new insight becomes visible to the poll only once emitted, with
    // a generatedOn timestamp guaranteed to be after the request was
    // submitted (real wall-clock time only moves forward from here).
    getPendingReview.emit([
      {
        ...PENDING_INSIGHT,
        insightId: "a0X000000000002",
        generatedOn: new Date().toISOString()
      }
    ]);

    await jest.advanceTimersByTimeAsync(2000);
    await flushPromises();

    const status = element.shadowRoot.querySelector(".generate-status");
    expect(status.textContent).toContain("Insight generated");
  });

  it("renders pending partner requests", async () => {
    const element = createElement("c-ps-ai-governance-console", {
      is: PsAiGovernanceConsole
    });
    document.body.appendChild(element);

    getInsightTypes.emit(INSIGHT_TYPES);
    getPendingReview.emit([]);
    getPendingRequests.emit([PENDING_REQUEST]);
    await flushPromises();

    expect(
      element.shadowRoot.querySelector(".request-row strong").textContent
    ).toBe("Acme Partner");
  });

  it("pre-fills the generate form when a request is actioned", async () => {
    actionRequest.mockResolvedValue({
      requestId: PENDING_REQUEST.requestId,
      partnerAccountId: PENDING_REQUEST.partnerAccountId,
      insightType: "PartnerHealthScore",
      notes: PENDING_REQUEST.notes
    });

    const element = createElement("c-ps-ai-governance-console", {
      is: PsAiGovernanceConsole
    });
    document.body.appendChild(element);

    getInsightTypes.emit(INSIGHT_TYPES);
    getPendingReview.emit([]);
    getPendingRequests.emit([PENDING_REQUEST]);
    await flushPromises();

    const actionButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Action");
    actionButton.click();
    await flushPromises();
    await flushPromises();
    await flushPromises();

    expect(actionRequest).toHaveBeenCalledWith({
      requestId: PENDING_REQUEST.requestId
    });

    const generateButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Generate");
    expect(generateButton.disabled).toBe(false);
  });

  it("dismisses a pending request", async () => {
    dismissRequest.mockResolvedValue();

    const element = createElement("c-ps-ai-governance-console", {
      is: PsAiGovernanceConsole
    });
    document.body.appendChild(element);

    getInsightTypes.emit(INSIGHT_TYPES);
    getPendingReview.emit([]);
    getPendingRequests.emit([PENDING_REQUEST]);
    await flushPromises();

    const dismissButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Dismiss");
    dismissButton.click();
    await flushPromises();

    expect(dismissRequest).toHaveBeenCalledWith({
      requestId: PENDING_REQUEST.requestId
    });
  });
});
