import { createElement } from "@lwc/engine-dom";
import NavMenu from "c/navMenu";
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

const mockNavigate = jest.fn();

jest.mock("lightning/navigation", () => {
  const {
    createTestWireAdapter
  } = require("@salesforce/wire-service-jest-util");

  const Navigate = Symbol("Navigate");
  const GenerateUrl = Symbol("GenerateUrl");

  const NavigationMixin = (Base) =>
    class extends Base {
      [Navigate](...args) {
        mockNavigate(...args);
      }
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
    Id: "item-home",
    Label: "Home",
    Type: "InternalLink",
    Target: "/home",
    AccessRestriction: "None",
    ParentId: null,
    Position: 0,
    TargetPrefs: null
  },
  {
    Id: "item-resources",
    Label: "Resources",
    Type: "InternalLink",
    Target: "/content-hub",
    AccessRestriction: "LoginRequired",
    ParentId: null,
    Position: 1,
    TargetPrefs: null
  },
  {
    Id: "item-resources-child",
    Label: "Training",
    Type: "InternalLink",
    Target: "/content-hub/training",
    AccessRestriction: "None",
    ParentId: "item-resources",
    Position: 0,
    TargetPrefs: null
  },
  {
    Id: "item-hidden",
    Label: "Hidden",
    Type: "InternalLink",
    Target: "/hidden",
    AccessRestriction: "HideAlways",
    ParentId: null,
    Position: 2,
    TargetPrefs: null
  }
];

describe("c-nav-menu", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders c-nav-menu-items for only the visible top-level items, with their nested children", async () => {
    const element = createElement("c-nav-menu", { is: NavMenu });
    element.menuName = "Default Navigation";

    document.body.appendChild(element);

    getNavigationMenuItems.emit(MENU_ITEMS);
    await flushPromises();

    const topLevelItems = element.shadowRoot.querySelectorAll(
      ".nav-item > c-nav-menu-items"
    );
    const labels = topLevelItems.forEach
      ? Array.from(topLevelItems).map((el) => el.item.label)
      : [];

    expect(labels).toEqual(["Home", "Resources"]);

    const childItems = element.shadowRoot.querySelectorAll(
      ".nav-subitem c-nav-menu-items"
    );
    expect(childItems).toHaveLength(1);
    expect(childItems[0].item.label).toBe("Training");
    expect(childItems[0].variant).toBe("submenu");
  });

  it("toggles the mobile hamburger menu open state", async () => {
    const element = createElement("c-nav-menu", { is: NavMenu });
    element.menuName = "Default Navigation";

    document.body.appendChild(element);

    getNavigationMenuItems.emit(MENU_ITEMS);
    await flushPromises();

    const toggle = element.shadowRoot.querySelector(".hamburger-toggle");
    expect(toggle.getAttribute("aria-expanded")).toBe("false");

    toggle.click();
    await flushPromises();

    expect(toggle.getAttribute("aria-expanded")).toBe("true");
    expect(element.shadowRoot.querySelector(".nav-list").classList).toContain(
      "is-open"
    );
  });

  it("closes the hamburger menu when a nav item reports navigation", async () => {
    const element = createElement("c-nav-menu", { is: NavMenu });
    element.menuName = "Default Navigation";

    document.body.appendChild(element);

    getNavigationMenuItems.emit(MENU_ITEMS);
    await flushPromises();

    element.shadowRoot.querySelector(".hamburger-toggle").click();
    await flushPromises();

    expect(element.shadowRoot.querySelector(".nav-list").classList).toContain(
      "is-open"
    );

    element.shadowRoot
      .querySelector(".nav-item > c-nav-menu-items")
      .dispatchEvent(new CustomEvent("navigation"));
    await flushPromises();

    expect(
      element.shadowRoot.querySelector(".nav-list").classList
    ).not.toContain("is-open");
  });

  it("renders the optional call-to-action button and navigates on click", async () => {
    const element = createElement("c-nav-menu", { is: NavMenu });
    element.menuName = "Default Navigation";
    element.buttonLabel = "Get Started";
    element.buttonRedirectPageAPIName = "Register-Deal";

    document.body.appendChild(element);

    getNavigationMenuItems.emit(MENU_ITEMS);
    await flushPromises();

    const button = element.shadowRoot.querySelector(".nav-cta");
    expect(button.label).toBe("Get Started");

    button.click();
    await flushPromises();

    expect(mockNavigate).toHaveBeenCalledWith({
      type: "comm__namedPage",
      attributes: { name: "Register-Deal" }
    });
  });

  it("does not render the call-to-action button when not configured", async () => {
    const element = createElement("c-nav-menu", { is: NavMenu });
    element.menuName = "Default Navigation";

    document.body.appendChild(element);

    getNavigationMenuItems.emit(MENU_ITEMS);
    await flushPromises();

    expect(element.shadowRoot.querySelector(".nav-cta")).toBeNull();
  });

  it("shows an inline error message when the wire adapter errors", async () => {
    const element = createElement("c-nav-menu", { is: NavMenu });
    element.menuName = "Default Navigation";

    document.body.appendChild(element);

    getNavigationMenuItems.error({ message: "No access." });
    await flushPromises();

    const errorMessage = element.shadowRoot.querySelector(".nav-error");
    expect(errorMessage.textContent).toBe("No access.");
  });
});
