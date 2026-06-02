import { createElement } from "@lwc/engine-dom";
import PsEmptyState from "c/psEmptyState";

describe("c-ps-empty-state", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders configured empty state text and emits action", () => {
    const element = createElement("c-ps-empty-state", {
      is: PsEmptyState
    });
    element.title = "All clear";
    element.message = "No urgent partner actions right now.";
    element.buttonLabel = "Refresh";
    const actionHandler = jest.fn();
    element.addEventListener("action", actionHandler);

    document.body.appendChild(element);

    const button = element.shadowRoot.querySelector("lightning-button");
    button.click();

    expect(element.shadowRoot.querySelector("h2").textContent).toBe(
      "All clear"
    );
    expect(element.shadowRoot.querySelector("p").textContent).toBe(
      "No urgent partner actions right now."
    );
    expect(button.label).toBe("Refresh");
    expect(actionHandler).toHaveBeenCalledTimes(1);
  });
});
