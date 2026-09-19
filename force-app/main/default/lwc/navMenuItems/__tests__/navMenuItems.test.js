import { createElement } from "@lwc/engine-dom";
import NavMenuItems from "c/navMenuItems";

jest.mock("@salesforce/community/basePath", () => ({ default: "/" }), {
  virtual: true
});

describe("c-nav-menu-items", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders a menu item and emits navigation when clicked", () => {
    const element = createElement("c-nav-menu-items", {
      is: NavMenuItems
    });
    element.item = { label: "Partner Home", type: "Unsupported" };
    element.variant = "submenu";
    const navigationHandler = jest.fn();
    element.addEventListener("navigation", navigationHandler);
    document.body.appendChild(element);

    const link = element.shadowRoot.querySelector("a");
    link.click();

    expect(link.textContent.trim()).toBe("Partner Home");
    expect(link.getAttribute("title")).toBe("Partner Home");
    expect(navigationHandler).toHaveBeenCalledTimes(1);
  });
});
