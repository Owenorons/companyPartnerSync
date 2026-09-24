import { createElement } from "@lwc/engine-dom";
import PsContentAdmin from "c/psContentAdmin";
import getAllContent from "@salesforce/apex/PartnerContentController.getAllContent";
import saveContent from "@salesforce/apex/PartnerContentController.saveContent";

jest.mock(
  "@salesforce/apex/PartnerContentController.getAllContent",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PartnerContentController.saveContent",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

const CONTENT = [
  {
    contentId: "content-1",
    title: "Pitch Deck",
    category: "Sales Deck",
    visibility: "All Partners",
    featured: true,
    isActive: true,
    partnerTier: null,
    partnerType: null,
    sortOrder: 10
  }
];

describe("c-ps-content-admin", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders a row per content record", async () => {
    const element = createElement("c-ps-content-admin", {
      is: PsContentAdmin
    });

    document.body.appendChild(element);

    getAllContent.emit(CONTENT);
    await flushPromises();

    const titleCell = element.shadowRoot.querySelector(".cell-title");
    expect(titleCell.textContent).toBe("Pitch Deck");
  });

  it("opens the edit modal with the selected row's data", async () => {
    const element = createElement("c-ps-content-admin", {
      is: PsContentAdmin
    });

    document.body.appendChild(element);

    getAllContent.emit(CONTENT);
    await flushPromises();

    const buttons = element.shadowRoot.querySelectorAll(
      'lightning-button[data-id="content-1"]'
    );
    const editButton = buttons[1];
    editButton.click();
    await flushPromises();

    const modal = element.shadowRoot.querySelector("c-ps-modal");
    expect(modal).not.toBeNull();

    const titleInput = element.shadowRoot.querySelector(
      "c-ps-modal lightning-input"
    );
    expect(titleInput.value).toBe("Pitch Deck");
  });

  it("saves the toggled active state without opening the modal", async () => {
    saveContent.mockResolvedValue({ ...CONTENT[0], isActive: false });

    const element = createElement("c-ps-content-admin", {
      is: PsContentAdmin
    });

    document.body.appendChild(element);

    getAllContent.emit(CONTENT);
    await flushPromises();

    const buttons = element.shadowRoot.querySelectorAll(
      'lightning-button[data-id="content-1"]'
    );
    const toggleButton = buttons[0];
    toggleButton.click();
    await flushPromises();

    expect(saveContent).toHaveBeenCalledWith({
      content: expect.objectContaining({
        contentId: "content-1",
        isActive: false
      })
    });
  });

  it("opens an empty New Content modal with Save disabled until a file is attached", async () => {
    const element = createElement("c-ps-content-admin", {
      is: PsContentAdmin
    });

    document.body.appendChild(element);

    getAllContent.emit(CONTENT);
    await flushPromises();

    Array.from(element.shadowRoot.querySelectorAll("lightning-button"))
      .find((button) => button.label === "Add New Content")
      .click();
    await flushPromises();

    const modal = element.shadowRoot.querySelector("c-ps-modal");
    expect(modal.title).toBe("New Content");

    const titleInput = element.shadowRoot.querySelector(
      "c-ps-modal lightning-input"
    );
    expect(titleInput.value).toBeFalsy();

    const saveButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Save");
    expect(saveButton.disabled).toBe(true);
  });

  it("creates new content once a file is uploaded", async () => {
    saveContent.mockResolvedValue({
      contentId: "content-2",
      title: "New Asset",
      contentDocumentId: "069xx0000000009AAA"
    });

    const element = createElement("c-ps-content-admin", {
      is: PsContentAdmin
    });

    document.body.appendChild(element);

    getAllContent.emit(CONTENT);
    await flushPromises();

    Array.from(element.shadowRoot.querySelectorAll("lightning-button"))
      .find((button) => button.label === "Add New Content")
      .click();
    await flushPromises();

    const titleInput = element.shadowRoot.querySelector(
      "c-ps-modal lightning-input"
    );
    titleInput.value = "New Asset";
    titleInput.dispatchEvent(new CustomEvent("change"));

    const fileUpload = element.shadowRoot.querySelector(
      "lightning-file-upload"
    );
    fileUpload.dispatchEvent(
      new CustomEvent("uploadfinished", {
        detail: {
          files: [{ documentId: "069xx0000000009AAA", name: "asset.pdf" }]
        }
      })
    );
    await flushPromises();

    const saveButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Save");
    expect(saveButton.disabled).toBe(false);

    saveButton.click();
    await flushPromises();

    expect(saveContent).toHaveBeenCalledWith({
      content: expect.objectContaining({
        title: "New Asset",
        contentDocumentId: "069xx0000000009AAA"
      })
    });
    expect(saveContent.mock.calls[0][0].content.contentId).toBeUndefined();
  });
});
