import { createElement } from "@lwc/engine-dom";
import PsMdfWorkspace from "c/psMdfWorkspace";
import submitRequest from "@salesforce/apex/MDFController.submitRequest";

jest.mock(
  "@salesforce/apex/MDFController.submitRequest",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-ps-mdf-workspace", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders the MDF budget, request form, and request list", () => {
    // Arrange
    const element = createElement("c-ps-mdf-workspace", {
      is: PsMdfWorkspace
    });

    // Act
    document.body.appendChild(element);

    // Assert
    expect(
      element.shadowRoot.querySelector("c-ps-mdf-budget-card")
    ).not.toBeNull();
    expect(
      element.shadowRoot.querySelector("c-ps-mdf-request-form")
    ).not.toBeNull();
    expect(element.shadowRoot.querySelector("c-ps-mdf-list")).not.toBeNull();
  });

  it("submits the request payload and refreshes the list on success", async () => {
    submitRequest.mockResolvedValue();

    const element = createElement("c-ps-mdf-workspace", {
      is: PsMdfWorkspace
    });

    document.body.appendChild(element);

    const requestPayload = {
      requestType: "Event",
      campaignName: "Fall Roadshow",
      requestedAmount: 5000,
      campaignDescription: ""
    };

    element.shadowRoot
      .querySelector("c-ps-mdf-request-form")
      .dispatchEvent(
        new CustomEvent("requestcreated", { detail: requestPayload })
      );
    await flushPromises();
    await flushPromises();

    expect(submitRequest).toHaveBeenCalledWith({ request: requestPayload });
    expect(element.shadowRoot.querySelector("c-ps-error-panel")).toBeNull();
  });

  it("shows an error panel when submission fails", async () => {
    submitRequest.mockRejectedValue({
      body: { message: "Campaign name is required." }
    });

    const element = createElement("c-ps-mdf-workspace", {
      is: PsMdfWorkspace
    });

    document.body.appendChild(element);

    element.shadowRoot
      .querySelector("c-ps-mdf-request-form")
      .dispatchEvent(new CustomEvent("requestcreated", { detail: {} }));
    await flushPromises();
    await flushPromises();

    const errorPanel = element.shadowRoot.querySelector("c-ps-error-panel");
    expect(errorPanel).not.toBeNull();
    expect(errorPanel.message).toBe("Campaign name is required.");
  });
});
