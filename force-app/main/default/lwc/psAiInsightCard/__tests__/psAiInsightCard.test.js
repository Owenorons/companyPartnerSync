import { createElement } from "@lwc/engine-dom";
import PsAiInsightCard from "c/psAiInsightCard";

describe("c-ps-ai-insight-card", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders only its reserved compatibility host", () => {
    const element = createElement("c-ps-ai-insight-card", {
      is: PsAiInsightCard
    });
    document.body.appendChild(element);

    expect(element.shadowRoot.childElementCount).toBe(0);
  });
});
