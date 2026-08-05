import { createElement } from "@lwc/engine-dom";
import PsFooter from "c/psFooter";
import getNavigationMenuItems from "@salesforce/apex/NavMenuItemsController.getNavigationMenuItems";

// c-ps-footer-list (rendered when footerMenuName is set) nests the real
// c-nav-menu-items, which pulls in these modules — same mock set as
// navMenu.test.js, since that component has the identical dependency chain.
jest.mock("@salesforce/community/basePath", () => ({ default: "/" }), {
  virtual: true
});

jest.mock("@salesforce/user/isGuest", () => ({ default: false }), {
  virtual: true
});

jest.mock(
  "@salesforce/apex/NavMenuItemsController.getNavigationMenuItems",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock("lightning/navigation", () => {
  const {
    createTestWireAdapter
  } = require("@salesforce/wire-service-jest-util");

  const Navigate = Symbol("Navigate");
  const GenerateUrl = Symbol("GenerateUrl");

  const NavigationMixin = (Base) =>
    class extends Base {
      [Navigate]() {}
      [GenerateUrl]() {
        return Promise.resolve("https://www.example.com");
      }
    };
  NavigationMixin.Navigate = Navigate;
  NavigationMixin.GenerateUrl = GenerateUrl;

  return {
    CurrentPageReference: createTestWireAdapter(jest.fn()),
    NavigationMixin
  };
});

const flushPromises = () => Promise.resolve();

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

  it("does not render the footer link nav when no menu name is configured", () => {
    const element = createElement("c-ps-footer", { is: PsFooter });

    document.body.appendChild(element);

    expect(element.shadowRoot.querySelector(".footer-links")).toBeNull();
  });

  it("renders c-ps-footer-list with the configured menu name", async () => {
    const element = createElement("c-ps-footer", { is: PsFooter });
    element.footerMenuName = "Footer Navigation";

    document.body.appendChild(element);

    getNavigationMenuItems.emit([]);
    await flushPromises();

    const footerList = element.shadowRoot.querySelector(
      ".footer-links c-ps-footer-list"
    );

    expect(footerList).not.toBeNull();
    expect(footerList.menuName).toBe("Footer Navigation");
  });
});
