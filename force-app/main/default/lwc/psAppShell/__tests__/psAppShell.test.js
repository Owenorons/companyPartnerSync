import { createElement } from "@lwc/engine-dom";
import PsAppShell from "c/psAppShell";

describe("c-ps-app-shell", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders the application navigation and slotted content", () => {
    // Arrange
    const element = createElement("c-ps-app-shell", {
      is: PsAppShell
    });

    // Act
    document.body.appendChild(element);

    // Assert
    expect(element.shadowRoot.querySelector("c-ps-side-nav")).not.toBeNull();
    expect(element.shadowRoot.querySelector("c-ps-top-nav")).not.toBeNull();
    expect(element.shadowRoot.querySelector("slot")).not.toBeNull();
  });
});
