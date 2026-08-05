import { createElement } from "@lwc/engine-dom";
import PsFooterList from "c/psFooterList";
import getNavigationMenuItems from "@salesforce/apex/NavMenuItemsController.getNavigationMenuItems";

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

const MENU_ITEMS = [
  {
    Id: "item-privacy",
    Label: "Privacy Policy",
    Type: "InternalLink",
    Target: "/privacy",
    AccessRestriction: "None",
    ParentId: null
  },
  {
    Id: "item-support",
    Label: "Support",
    Type: "InternalLink",
    Target: "/support",
    AccessRestriction: "LoginRequired",
    ParentId: null
  },
  {
    Id: "item-hidden",
    Label: "Hidden",
    Type: "InternalLink",
    Target: "/hidden",
    AccessRestriction: "HideAlways",
    ParentId: null
  }
];

describe("c-ps-footer-list", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders only the visible items as c-nav-menu-items", async () => {
    const element = createElement("c-ps-footer-list", { is: PsFooterList });
    element.menuName = "Footer Navigation";

    document.body.appendChild(element);

    getNavigationMenuItems.emit(MENU_ITEMS);
    await flushPromises();

    const items = Array.from(
      element.shadowRoot.querySelectorAll("c-nav-menu-items")
    ).map((el) => el.item.label);

    expect(items).toEqual(["Privacy Policy", "Support"]);
  });

  it("renders nothing when the menu has no items", async () => {
    const element = createElement("c-ps-footer-list", { is: PsFooterList });
    element.menuName = "Footer Navigation";

    document.body.appendChild(element);

    getNavigationMenuItems.emit([]);
    await flushPromises();

    expect(element.shadowRoot.querySelector(".footer-link-list")).toBeNull();
  });
});
