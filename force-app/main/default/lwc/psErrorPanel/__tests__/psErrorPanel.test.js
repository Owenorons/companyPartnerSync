import { createElement } from "@lwc/engine-dom";
import PsErrorPanel from "c/psErrorPanel";

describe("c-ps-error-panel", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders the configured error message", () => {
    const element = createElement("c-ps-error-panel", {
      is: PsErrorPanel
    });
    element.message = "Partner records are unavailable.";
    document.body.appendChild(element);

    expect(element.shadowRoot.querySelector("h2").textContent).toBe(
      "Something went wrong"
    );
    expect(element.shadowRoot.querySelector("p").textContent).toBe(
      "Partner records are unavailable."
    );
  });
});
