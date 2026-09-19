import { createElement } from "@lwc/engine-dom";
import PsStatusBadge from "c/psStatusBadge";

describe("c-ps-status-badge", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders its label, variant, and size", () => {
    const element = createElement("c-ps-status-badge", {
      is: PsStatusBadge
    });
    element.label = "Ready";
    element.variant = "success";
    element.size = "lg";
    document.body.appendChild(element);

    const badge = element.shadowRoot.querySelector("span");
    expect(badge.textContent.trim()).toBe("Ready");
    expect(badge.classList).toContain("badge-success");
    expect(badge.classList).toContain("badge-lg");
  });
});
