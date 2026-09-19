import { createElement } from "@lwc/engine-dom";
import PartnerSyncThemeLayout from "c/partnerSyncThemeLayout";

describe("c-partner-sync-theme-layout", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders the header, main, and footer regions", () => {
    const element = createElement("c-partner-sync-theme-layout", {
      is: PartnerSyncThemeLayout
    });

    document.body.appendChild(element);

    expect(element.shadowRoot.querySelector("header")).not.toBeNull();
    expect(element.shadowRoot.querySelector("main")).not.toBeNull();
    expect(element.shadowRoot.querySelector("footer")).not.toBeNull();
  });

  it("keeps the header, main, and footer regions as bare, empty-by-default slots", () => {
    const element = createElement("c-partner-sync-theme-layout", {
      is: PartnerSyncThemeLayout
    });

    document.body.appendChild(element);

    const headerSlot = element.shadowRoot.querySelector(
      'header slot[name="header"]'
    );
    const footerSlot = element.shadowRoot.querySelector(
      'footer slot[name="footer"]'
    );

    expect(headerSlot).not.toBeNull();
    expect(headerSlot.children).toHaveLength(0);
    expect(element.shadowRoot.querySelector("main slot")).not.toBeNull();
    expect(footerSlot).not.toBeNull();
    expect(footerSlot.children).toHaveLength(0);
  });
});
