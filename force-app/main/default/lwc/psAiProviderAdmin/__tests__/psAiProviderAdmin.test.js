import { createElement } from "@lwc/engine-dom";
import PsAiProviderAdmin from "c/psAiProviderAdmin";
import getProviders from "@salesforce/apex/AIInsightController.getProviders";
import testProviderConnection from "@salesforce/apex/AIInsightController.testProviderConnection";

jest.mock(
  "@salesforce/apex/AIInsightController.getProviders",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/AIInsightController.testProviderConnection",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

const PROVIDERS = [
  {
    developerName: "OpenAI",
    providerName: "OpenAI",
    providerType: "OpenAI",
    active: true,
    connectionStatus: "Not Tested",
    lastTestDate: null,
    lastTestResult: null
  }
];

describe("c-ps-ai-provider-admin", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders a row per configured provider", async () => {
    const element = createElement("c-ps-ai-provider-admin", {
      is: PsAiProviderAdmin
    });

    document.body.appendChild(element);

    getProviders.emit(PROVIDERS);
    await flushPromises();

    const titleCell = element.shadowRoot.querySelector(".cell-title");
    expect(titleCell.textContent).toBe("OpenAI");
  });

  it("tests the connection for the selected provider and refreshes", async () => {
    testProviderConnection.mockResolvedValue("Connection successful.");

    const element = createElement("c-ps-ai-provider-admin", {
      is: PsAiProviderAdmin
    });

    document.body.appendChild(element);

    getProviders.emit(PROVIDERS);
    await flushPromises();

    const testButton = element.shadowRoot.querySelector(
      'lightning-button[data-name="OpenAI"]'
    );
    testButton.click();
    await flushPromises();
    await flushPromises();

    expect(testProviderConnection).toHaveBeenCalledWith({
      providerDeveloperName: "OpenAI"
    });
  });

  it("shows an error panel when the connection test fails", async () => {
    testProviderConnection.mockRejectedValue({
      body: { message: "Unknown AI provider: OpenAI" }
    });

    const element = createElement("c-ps-ai-provider-admin", {
      is: PsAiProviderAdmin
    });

    document.body.appendChild(element);

    getProviders.emit(PROVIDERS);
    await flushPromises();

    const testButton = element.shadowRoot.querySelector(
      'lightning-button[data-name="OpenAI"]'
    );
    testButton.click();
    await flushPromises();
    await flushPromises();

    const errorPanel = element.shadowRoot.querySelector("c-ps-error-panel");
    expect(errorPanel).not.toBeNull();
    expect(errorPanel.message).toBe("Unknown AI provider: OpenAI");
  });
});
