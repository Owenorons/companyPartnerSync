import { createElement } from "@lwc/engine-dom";
import PsPartnerNextBestActions from "c/psPartnerNextBestActions";
import getMyNextBestActions from "@salesforce/apex/PartnerAIController.getMyNextBestActions";

jest.mock(
  "@salesforce/apex/PartnerAIController.getMyNextBestActions",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-ps-partner-next-best-actions", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders recommendations returned by the governed Apex service", async () => {
    getMyNextBestActions.mockResolvedValue([
      {
        actionId: "action-1",
        priority: "High",
        sourceSignal: "Readiness",
        title: "Complete training",
        recommendation: "Assign the remaining course.",
        reason: "The partner is one course short.",
        confidence: 91.6
      }
    ]);
    const element = createElement("c-ps-partner-next-best-actions", {
      is: PsPartnerNextBestActions
    });
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    const card = element.shadowRoot.querySelector(".action-card");
    expect(card.querySelector("h3").textContent).toBe("Complete training");
    expect(card.querySelector(".confidence strong").textContent).toBe("92%");
  });

  it("renders a safe service error", async () => {
    getMyNextBestActions.mockRejectedValue({
      body: { message: "Recommendations are disabled." }
    });
    const element = createElement("c-ps-partner-next-best-actions", {
      is: PsPartnerNextBestActions
    });
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "Recommendations are disabled."
    );
  });
});
