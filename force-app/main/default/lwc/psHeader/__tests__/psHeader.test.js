import { createElement } from "@lwc/engine-dom";
import PsHeader from "c/psHeader";

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

describe("c-ps-header", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders the logo, nav menu, and notification bell", () => {
    const element = createElement("c-ps-header", { is: PsHeader });

    document.body.appendChild(element);

    expect(element.shadowRoot.querySelector("c-ps-logo")).not.toBeNull();
    expect(element.shadowRoot.querySelector("c-nav-menu")).not.toBeNull();
    expect(
      element.shadowRoot.querySelector("c-ps-notification-bell")
    ).not.toBeNull();
  });

  it("forwards logo properties to c-ps-logo", () => {
    const element = createElement("c-ps-header", { is: PsHeader });
    element.logoUrl = "/resource/PartnerSync_Logo";
    element.wordmark = "Acme Partners";
    element.homePageName = "Home";

    document.body.appendChild(element);

    const logo = element.shadowRoot.querySelector("c-ps-logo");
    expect(logo.logoUrl).toBe("/resource/PartnerSync_Logo");
    expect(logo.wordmark).toBe("Acme Partners");
    expect(logo.homePageName).toBe("Home");
  });

  it("forwards nav menu properties to c-nav-menu", () => {
    const element = createElement("c-ps-header", { is: PsHeader });
    element.menuName = "Main Menu";
    element.buttonLabel = "Register Deal";
    element.buttonRedirectPageAPIName = "Register-Deal";

    document.body.appendChild(element);

    const menu = element.shadowRoot.querySelector("c-nav-menu");
    expect(menu.menuName).toBe("Main Menu");
    expect(menu.buttonLabel).toBe("Register Deal");
    expect(menu.buttonRedirectPageAPIName).toBe("Register-Deal");
  });
});
