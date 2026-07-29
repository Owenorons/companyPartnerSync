import { createElement } from "@lwc/engine-dom";
import PsPartnerApplicationForm from "c/psPartnerApplicationForm";
import submitApplication from "@salesforce/apex/PartnerApplicationController.submitApplication";

jest.mock(
  "@salesforce/apex/PartnerApplicationController.submitApplication",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

// Field order in the template: companyName, website, country, region
// (inputs) / requestedTier, partnerType (comboboxes) / submittedByContactName,
// submittedByEmail, phone, businessEmail (inputs).
function fillRequiredFields(element) {
  const inputs = element.shadowRoot.querySelectorAll("lightning-input");
  const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");

  const setInputValue = (input, value) => {
    input.value = value;
    input.dispatchEvent(new CustomEvent("change"));
  };

  const setComboboxValue = (combobox, value) => {
    combobox.value = value;
    combobox.dispatchEvent(new CustomEvent("change", { detail: { value } }));
  };

  setInputValue(inputs[0], "Acme Logistics"); // companyName
  setComboboxValue(comboboxes[0], "Gold"); // requestedTier
  setComboboxValue(comboboxes[1], "Reseller"); // partnerType
  setInputValue(inputs[5], "dana@acmelogistics.com"); // submittedByEmail
  setInputValue(inputs[7], "hello@acmelogistics.com"); // businessEmail
}

describe("c-ps-partner-application-form", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("disables submit until the required fields are filled in", async () => {
    const element = createElement("c-ps-partner-application-form", {
      is: PsPartnerApplicationForm
    });
    document.body.appendChild(element);
    await flushPromises();

    const button = element.shadowRoot.querySelector("lightning-button");
    expect(button.disabled).toBe(true);

    fillRequiredFields(element);
    await flushPromises();

    expect(button.disabled).toBe(false);
  });

  it("submits the application and shows the success state", async () => {
    submitApplication.mockResolvedValue({
      applicationId: "a03xx0000000001",
      applicationNumber: "PA-000001",
      status: "Submitted"
    });

    const element = createElement("c-ps-partner-application-form", {
      is: PsPartnerApplicationForm
    });
    document.body.appendChild(element);
    await flushPromises();

    fillRequiredFields(element);
    await flushPromises();

    element.shadowRoot
      .querySelector("form")
      .dispatchEvent(new CustomEvent("submit"));
    await flushPromises();
    await flushPromises();

    expect(submitApplication).toHaveBeenCalledWith({
      request: expect.objectContaining({
        companyName: "Acme Logistics",
        businessEmail: "hello@acmelogistics.com",
        requestedTier: "Gold",
        partnerType: "Reseller",
        submittedByEmail: "dana@acmelogistics.com"
      })
    });

    expect(
      element.shadowRoot.querySelector(".success-card h2").textContent
    ).toBe("Application submitted");
    expect(
      element.shadowRoot.querySelector(".success-card").textContent
    ).toContain("PA-000001");
  });

  it("shows an error panel when the Apex call fails", async () => {
    submitApplication.mockRejectedValue({
      body: {
        message:
          "A partner application already exists for this company or email."
      }
    });

    const element = createElement("c-ps-partner-application-form", {
      is: PsPartnerApplicationForm
    });
    document.body.appendChild(element);
    await flushPromises();

    fillRequiredFields(element);
    await flushPromises();

    element.shadowRoot
      .querySelector("form")
      .dispatchEvent(new CustomEvent("submit"));
    await flushPromises();
    await flushPromises();

    const errorPanel = element.shadowRoot.querySelector("c-ps-error-panel");
    expect(errorPanel).not.toBeNull();
    expect(errorPanel.message).toBe(
      "A partner application already exists for this company or email."
    );
  });
});
