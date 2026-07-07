import { createElement } from "@lwc/engine-dom";
import PsContentCard from "c/psContentCard";

describe("c-ps-content-card", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders content and dispatches a download event", () => {
    // Arrange
    const element = createElement("c-ps-content-card", {
      is: PsContentCard
    });
    element.content = {
      category: "Sales",
      contentId: "content-1",
      description: "Product overview",
      featured: true,
      title: "Partner guide"
    };
    const downloadHandler = jest.fn();
    element.addEventListener("download", downloadHandler);

    // Act
    document.body.appendChild(element);
    element.shadowRoot.querySelector("button").click();

    // Assert
    expect(element.shadowRoot.querySelector(".category").textContent).toBe(
      "Sales"
    );
    expect(element.shadowRoot.querySelector(".featured").textContent).toBe(
      "Featured"
    );
    expect(element.shadowRoot.querySelector("h3").textContent).toBe(
      "Partner guide"
    );
    expect(element.shadowRoot.querySelector("p").textContent).toBe(
      "Product overview"
    );
    expect(downloadHandler).toHaveBeenCalledTimes(1);
    expect(downloadHandler.mock.calls[0][0].detail).toEqual({
      contentId: "content-1"
    });
  });

  it("renders safe fallback copy when content is missing", () => {
    const element = createElement("c-ps-content-card", {
      is: PsContentCard
    });

    document.body.appendChild(element);

    expect(element.shadowRoot.querySelector(".category").textContent).toBe(
      "General"
    );
    expect(element.shadowRoot.querySelector("h3").textContent).toBe(
      "Untitled content"
    );
    expect(element.shadowRoot.querySelector("button").disabled).toBe(true);
  });
});
