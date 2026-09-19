import { createElement } from "@lwc/engine-dom";
import PsFilterPanel from "c/psFilterPanel";

describe("c-ps-filter-panel", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders only its reserved compatibility host", () => {
    const element = createElement("c-ps-filter-panel", { is: PsFilterPanel });
    document.body.appendChild(element);

    expect(element.shadowRoot.childElementCount).toBe(0);
  });
});
