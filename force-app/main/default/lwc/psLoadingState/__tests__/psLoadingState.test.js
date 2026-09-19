import { createElement } from "@lwc/engine-dom";
import PsLoadingState from "c/psLoadingState";

describe("c-ps-loading-state", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders the configured loading message and spinner", () => {
    const element = createElement("c-ps-loading-state", {
      is: PsLoadingState
    });
    element.message = "Loading partner readiness";
    document.body.appendChild(element);

    expect(element.shadowRoot.querySelector("p").textContent).toBe(
      "Loading partner readiness"
    );
    expect(element.shadowRoot.querySelector(".spinner")).not.toBeNull();
  });
});
