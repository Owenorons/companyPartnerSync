import { createElement } from "@lwc/engine-dom";
import PsFooter from "c/psFooter";

describe("c-ps-footer", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders the copyright line with the default company name and current year", () => {
    const element = createElement("c-ps-footer", { is: PsFooter });

    document.body.appendChild(element);

    const copyright = element.shadowRoot.querySelector(".copyright");
    const currentYear = new Date().getFullYear();

    expect(copyright.textContent).toBe(
      `© ${currentYear} PartnerSync. All rights reserved.`
    );
  });

  it("uses a configured company name", () => {
    const element = createElement("c-ps-footer", { is: PsFooter });
    element.companyName = "Acme Corp";

    document.body.appendChild(element);

    const copyright = element.shadowRoot.querySelector(".copyright");
    const currentYear = new Date().getFullYear();

    expect(copyright.textContent).toBe(
      `© ${currentYear} Acme Corp. All rights reserved.`
    );
  });

  it("renders placeholder footer links", () => {
    const element = createElement("c-ps-footer", { is: PsFooter });

    document.body.appendChild(element);

    const links = Array.from(
      element.shadowRoot.querySelectorAll(".footer-links a")
    ).map((link) => link.textContent);

    expect(links).toEqual(["Privacy Policy", "Terms of Service", "Support"]);
  });
});
