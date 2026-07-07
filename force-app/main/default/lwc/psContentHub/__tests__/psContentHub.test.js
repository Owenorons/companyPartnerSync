import { createElement } from "@lwc/engine-dom";
import PsContentHub from "c/psContentHub";
import getAvailableContent from "@salesforce/apex/PartnerContentController.getAvailableContent";
import getCategories from "@salesforce/apex/PartnerContentController.getCategories";
import getDownloadUrl from "@salesforce/apex/PartnerContentController.getDownloadUrl";

jest.mock(
  "@salesforce/apex/PartnerContentController.getAvailableContent",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PartnerContentController.getCategories",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PartnerContentController.getDownloadUrl",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-ps-content-hub", () => {
  const originalOpen = window.open;

  beforeEach(() => {
    window.open = jest.fn();
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    window.open = originalOpen;
    jest.clearAllMocks();
  });

  it("renders available content and category options", async () => {
    const element = createElement("c-ps-content-hub", {
      is: PsContentHub
    });

    document.body.appendChild(element);

    getCategories.emit([{ label: "Sales", value: "Sales" }]);
    getAvailableContent.emit([
      {
        contentId: "content-1",
        title: "Pitch Deck",
        description: "Partner sales deck",
        category: "Sales",
        featured: true
      }
    ]);
    await flushPromises();

    const cards = element.shadowRoot.querySelectorAll("c-ps-content-card");
    const category = element.shadowRoot.querySelector("lightning-combobox");

    expect(cards.length).toBeGreaterThan(0);
    expect(category.options).toEqual([
      { label: "All Categories", value: "" },
      { label: "Sales", value: "Sales" }
    ]);
  });

  it("opens the generated download URL", async () => {
    getDownloadUrl.mockResolvedValue({
      downloadUrl: "https://example.com/content"
    });

    const element = createElement("c-ps-content-hub", {
      is: PsContentHub
    });

    document.body.appendChild(element);

    getAvailableContent.emit([
      {
        contentId: "content-1",
        title: "Pitch Deck",
        category: "Sales"
      }
    ]);
    await flushPromises();

    element.shadowRoot
      .querySelector("c-ps-content-card")
      .dispatchEvent(
        new CustomEvent("download", { detail: { contentId: "content-1" } })
      );
    await flushPromises();

    expect(getDownloadUrl).toHaveBeenCalledWith({ contentId: "content-1" });
    expect(window.open).toHaveBeenCalledWith(
      "https://example.com/content",
      "_blank"
    );
  });
});
