import { createElement } from "@lwc/engine-dom";
import PsMdfRequestForm from "c/psMdfRequestForm";

describe("c-ps-mdf-request-form", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("emits requestcreated with the full request payload on submit", async () => {
    const element = createElement("c-ps-mdf-request-form", {
      is: PsMdfRequestForm
    });
    const handler = jest.fn();
    element.addEventListener("requestcreated", handler);

    document.body.appendChild(element);

    element.shadowRoot
      .querySelector("lightning-combobox")
      .dispatchEvent(new CustomEvent("change", { detail: { value: "Event" } }));

    const [campaignNameInput, requestedAmountInput] =
      element.shadowRoot.querySelectorAll("lightning-input");
    campaignNameInput.value = "Fall Roadshow";
    campaignNameInput.dispatchEvent(new CustomEvent("change"));
    requestedAmountInput.value = "5000";
    requestedAmountInput.dispatchEvent(new CustomEvent("change"));

    element.shadowRoot
      .querySelector("form")
      .dispatchEvent(new CustomEvent("submit", { cancelable: true }));

    expect(handler).toHaveBeenCalledTimes(1);
    expect(handler.mock.calls[0][0].detail).toEqual({
      requestType: "Event",
      campaignName: "Fall Roadshow",
      requestedAmount: 5000,
      campaignDescription: ""
    });
  });
});
