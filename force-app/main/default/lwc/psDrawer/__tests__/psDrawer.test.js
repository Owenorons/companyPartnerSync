import { createElement } from "@lwc/engine-dom";
import PsDrawer from "c/psDrawer";

describe("c-ps-drawer", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders the given title and defaults to the right position", () => {
    const element = createElement("c-ps-drawer", { is: PsDrawer });
    element.title = "Notifications";

    document.body.appendChild(element);

    const heading = element.shadowRoot.querySelector(".drawer-header h2");
    expect(heading.textContent).toBe("Notifications");
    expect(
      element.shadowRoot.querySelector(".drawer-panel").className
    ).toContain("drawer-right");
  });

  it("honors the position api property", () => {
    const element = createElement("c-ps-drawer", { is: PsDrawer });
    element.position = "left";

    document.body.appendChild(element);

    expect(
      element.shadowRoot.querySelector(".drawer-panel").className
    ).toContain("drawer-left");
  });

  it("dispatches close when the close button is clicked", () => {
    const element = createElement("c-ps-drawer", { is: PsDrawer });
    document.body.appendChild(element);

    const closeHandler = jest.fn();
    element.addEventListener("close", closeHandler);

    element.shadowRoot.querySelector(".drawer-close").click();

    expect(closeHandler).toHaveBeenCalledTimes(1);
  });

  it("dispatches close on Escape key", () => {
    const element = createElement("c-ps-drawer", { is: PsDrawer });
    document.body.appendChild(element);

    const closeHandler = jest.fn();
    element.addEventListener("close", closeHandler);

    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));

    expect(closeHandler).toHaveBeenCalledTimes(1);
  });
});
