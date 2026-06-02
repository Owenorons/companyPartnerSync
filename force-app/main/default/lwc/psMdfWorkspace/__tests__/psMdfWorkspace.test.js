import { createElement } from "@lwc/engine-dom";
import PsMdfWorkspace from "c/psMdfWorkspace";

describe("c-ps-mdf-workspace", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders the MDF budget, request form, and request list", () => {
    // Arrange
    const element = createElement("c-ps-mdf-workspace", {
      is: PsMdfWorkspace
    });

    // Act
    document.body.appendChild(element);

    // Assert
    expect(
      element.shadowRoot.querySelector("c-ps-mdf-budget-card")
    ).not.toBeNull();
    expect(
      element.shadowRoot.querySelector("c-ps-mdf-request-form")
    ).not.toBeNull();
    expect(element.shadowRoot.querySelector("c-ps-mdf-list")).not.toBeNull();
  });
});
