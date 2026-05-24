import { createElement } from "@lwc/engine-dom";
import PsSideNav from "c/psSideNav";

describe("c-ps-side-nav", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders Dashboard as the default active item", () => {
    const element = createElement("c-ps-side-nav", {
      is: PsSideNav
    });

    document.body.appendChild(element);

    const activeButton = element.shadowRoot.querySelector(".nav-item.active");

    expect(activeButton.textContent).toContain("Dashboard");
    expect(activeButton.getAttribute("aria-label")).toBe("Dashboard");
    expect(activeButton.getAttribute("title")).toBe("Dashboard");
    expect(activeButton.getAttribute("aria-current")).toBe("page");

    const activeIcon = activeButton.querySelector("lightning-icon");
    expect(activeIcon.alternativeText).toBe("");

    const assistiveText = activeButton.querySelector(".slds-assistive-text");
    expect(assistiveText.textContent).toBe("Open Dashboard");
  });

  it("uses the active item provided by the parent", () => {
    const element = createElement("c-ps-side-nav", {
      is: PsSideNav
    });
    element.activeItem = "deals";

    document.body.appendChild(element);

    const activeButton = element.shadowRoot.querySelector(".nav-item.active");

    expect(activeButton.textContent).toContain("Deals");
  });

  it("updates active state and emits selected item when a nav item is clicked", async () => {
    const element = createElement("c-ps-side-nav", {
      is: PsSideNav
    });
    const navigateHandler = jest.fn();
    element.addEventListener("navigate", navigateHandler);

    document.body.appendChild(element);

    const leadsButton = element.shadowRoot.querySelector(
      'a[data-name="leads"]'
    );
    leadsButton.click();
    await Promise.resolve();

    const activeButton = element.shadowRoot.querySelector(".nav-item.active");

    expect(activeButton.textContent).toContain("Leads");
    expect(navigateHandler).toHaveBeenCalledTimes(1);
    expect(navigateHandler.mock.calls[0][0].detail).toEqual({
      name: "leads",
      label: "Leads"
    });
  });
});
