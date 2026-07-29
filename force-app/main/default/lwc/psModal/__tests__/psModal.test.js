import { createElement } from "@lwc/engine-dom";
import PsModal from "c/psModal";

describe("c-ps-modal", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders the given title and slotted content", () => {
    const element = createElement("c-ps-modal", { is: PsModal });
    element.title = "Grant Access";

    document.body.appendChild(element);

    const heading = element.shadowRoot.querySelector(".modal-header h2");
    expect(heading.textContent).toBe("Grant Access");
  });

  it("dispatches close when the close button is clicked", () => {
    const element = createElement("c-ps-modal", { is: PsModal });
    document.body.appendChild(element);

    const closeHandler = jest.fn();
    element.addEventListener("close", closeHandler);

    element.shadowRoot.querySelector(".modal-close").click();

    expect(closeHandler).toHaveBeenCalledTimes(1);
  });

  it("dispatches close when the backdrop is clicked, but not the panel", () => {
    const element = createElement("c-ps-modal", { is: PsModal });
    document.body.appendChild(element);

    const closeHandler = jest.fn();
    element.addEventListener("close", closeHandler);

    element.shadowRoot.querySelector(".modal-panel").click();
    expect(closeHandler).not.toHaveBeenCalled();

    element.shadowRoot.querySelector(".modal-backdrop").click();
    expect(closeHandler).toHaveBeenCalledTimes(1);
  });

  it("dispatches close on Escape key", () => {
    const element = createElement("c-ps-modal", { is: PsModal });
    document.body.appendChild(element);

    const closeHandler = jest.fn();
    element.addEventListener("close", closeHandler);

    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape" }));

    expect(closeHandler).toHaveBeenCalledTimes(1);
  });
});
