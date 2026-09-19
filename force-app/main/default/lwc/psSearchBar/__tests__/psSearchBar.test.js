import { createElement } from "@lwc/engine-dom";
import PsSearchBar from "c/psSearchBar";

describe("c-ps-search-bar", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders only its reserved compatibility host", () => {
    const element = createElement("c-ps-search-bar", { is: PsSearchBar });
    document.body.appendChild(element);

    expect(element.shadowRoot.childElementCount).toBe(0);
  });
});
