import { createElement } from "@lwc/engine-dom";
import PsTopNav from "c/psTopNav";

describe("c-ps-top-nav", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders the default eyebrow, title, and notification bell", () => {
    const element = createElement("c-ps-top-nav", { is: PsTopNav });

    document.body.appendChild(element);

    expect(element.shadowRoot.querySelector(".eyebrow").textContent).toBe(
      "Partner Portal"
    );
    expect(element.shadowRoot.querySelector(".title").textContent).toBe(
      "PartnerSync Accelerator"
    );
    expect(
      element.shadowRoot.querySelector("c-ps-notification-bell")
    ).not.toBeNull();
  });

  it("renders configured eyebrow and title", () => {
    const element = createElement("c-ps-top-nav", { is: PsTopNav });
    element.eyebrow = "Internal Tools";
    element.title = "Deal Review Console";

    document.body.appendChild(element);

    expect(element.shadowRoot.querySelector(".eyebrow").textContent).toBe(
      "Internal Tools"
    );
    expect(element.shadowRoot.querySelector(".title").textContent).toBe(
      "Deal Review Console"
    );
  });
});
