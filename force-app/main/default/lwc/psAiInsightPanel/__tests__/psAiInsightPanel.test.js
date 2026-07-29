import { createElement } from "@lwc/engine-dom";
import PsAiInsightPanel from "c/psAiInsightPanel";
import getMyInsights from "@salesforce/apex/PartnerAIController.getMyInsights";

jest.mock(
  "@salesforce/apex/PartnerAIController.getMyInsights",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-ps-ai-insight-panel", () => {
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
});
