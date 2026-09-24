import { createElement } from "@lwc/engine-dom";
import PsAiInsightPanel from "c/psAiInsightPanel";
import getMyInsights from "@salesforce/apex/PartnerAIController.getMyInsights";
import getInsightTypes from "@salesforce/apex/PartnerAIController.getInsightTypes";
import submitInsightRequest from "@salesforce/apex/PartnerAIController.submitInsightRequest";
import getMyInsightRequests from "@salesforce/apex/PartnerAIController.getMyInsightRequests";

jest.mock(
  "@salesforce/apex/PartnerAIController.getMyInsights",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PartnerAIController.getInsightTypes",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PartnerAIController.submitInsightRequest",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PartnerAIController.getMyInsightRequests",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const INSIGHT_TYPES = [
  { developerName: "PartnerHealthScore", label: "Partner Health Score" }
];

const flushPromises = () => Promise.resolve();

describe("c-ps-ai-insight-panel", () => {
  beforeEach(() => {
    getInsightTypes.mockResolvedValue(INSIGHT_TYPES);
    getMyInsightRequests.mockResolvedValue([]);
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders governed insights with bounded confidence", async () => {
    getMyInsights.mockResolvedValue([
      {
        insightId: "a10xx000000001",
        insightType: "Partner Health",
        summary: "Engagement is improving.",
        recommendation: "Schedule a quarterly review.",
        reason: "Recent enablement activity increased.",
        confidence: 120
      }
    ]);

    const element = createElement("c-ps-ai-insight-panel", {
      is: PsAiInsightPanel
    });
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    const card = element.shadowRoot.querySelector(".insight-card");
    expect(card).not.toBeNull();
    expect(card.querySelector("h3").textContent).toBe("Partner Health");
    expect(card.querySelector(".score-circle").textContent).toBe("120");
    expect(card.querySelector(".confidence-fill").style.width).toBe("100%");
  });

  it("renders an empty state when no insights exist", async () => {
    getMyInsights.mockResolvedValue([]);

    const element = createElement("c-ps-ai-insight-panel", {
      is: PsAiInsightPanel
    });
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-empty-state")).not.toBeNull();
  });

  it("renders a safe provider error", async () => {
    getMyInsights.mockRejectedValue({
      body: { message: "AI access is disabled for this tenant." }
    });

    const element = createElement("c-ps-ai-insight-panel", {
      is: PsAiInsightPanel
    });
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "AI access is disabled for this tenant."
    );
  });

  it("disables the request submit button until an insight type is chosen", async () => {
    getMyInsights.mockResolvedValue([]);

    const element = createElement("c-ps-ai-insight-panel", {
      is: PsAiInsightPanel
    });
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    const submitButton = element.shadowRoot.querySelector(".request-submit");
    expect(submitButton.disabled).toBe(true);

    element.shadowRoot
      .querySelector("lightning-combobox")
      .dispatchEvent(
        new CustomEvent("change", { detail: { value: "PartnerHealthScore" } })
      );
    await flushPromises();

    expect(submitButton.disabled).toBe(false);
  });

  it("submits a request and shows a confirmation instead of a live spinner", async () => {
    getMyInsights.mockResolvedValue([]);
    submitInsightRequest.mockResolvedValue();
    getMyInsightRequests.mockResolvedValueOnce([]).mockResolvedValueOnce([
      {
        requestId: "a0Y000000000001",
        insightType: "PartnerHealthScore",
        insightTypeLabel: "Partner Health Score",
        status: "New"
      }
    ]);

    const element = createElement("c-ps-ai-insight-panel", {
      is: PsAiInsightPanel
    });
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    element.shadowRoot
      .querySelector("lightning-combobox")
      .dispatchEvent(
        new CustomEvent("change", { detail: { value: "PartnerHealthScore" } })
      );
    await flushPromises();

    element.shadowRoot.querySelector(".request-submit").click();
    await flushPromises();
    await flushPromises();
    await flushPromises();

    expect(submitInsightRequest).toHaveBeenCalledWith({
      insightType: "PartnerHealthScore",
      notes: ""
    });
    expect(
      element.shadowRoot.querySelector(".request-confirmation").textContent
    ).toContain("Request submitted");
    expect(
      element.shadowRoot.querySelector(".my-requests li").textContent
    ).toContain("Partner Health Score");
  });
});
