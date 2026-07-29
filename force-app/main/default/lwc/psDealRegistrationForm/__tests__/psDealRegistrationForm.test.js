import { createElement } from "@lwc/engine-dom";
import PsDealRegistrationForm from "c/psDealRegistrationForm";
import getEligibleOpportunities from "@salesforce/apex/DealRegistrationController.getEligibleOpportunities";
import createDealRegistration from "@salesforce/apex/DealRegistrationController.createDealRegistration";

jest.mock(
  "@salesforce/apex/DealRegistrationController.getEligibleOpportunities",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/DealRegistrationController.createDealRegistration",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-ps-deal-registration-form", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders an opportunity option for each eligible opportunity", async () => {
    const element = createElement("c-ps-deal-registration-form", {
      is: PsDealRegistrationForm
    });

    document.body.appendChild(element);

    getEligibleOpportunities.emit([
      { opportunityId: "opp-1", name: "Acme Renewal" }
    ]);
    await flushPromises();

    const combobox = element.shadowRoot.querySelector("lightning-combobox");
    expect(combobox.options).toEqual([
      { label: "Acme Renewal", value: "opp-1" }
    ]);
  });

  it("shows the empty state when there are no eligible opportunities", async () => {
    const element = createElement("c-ps-deal-registration-form", {
      is: PsDealRegistrationForm
    });

    document.body.appendChild(element);

    getEligibleOpportunities.emit([]);
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-empty-state")).not.toBeNull();
    expect(element.shadowRoot.querySelector("form")).toBeNull();
  });

  it("submits the selected opportunity and shows the success card", async () => {
    createDealRegistration.mockResolvedValue({
      dealRegistrationId: "deal-1",
      dealRegistrationNumber: "DR-0001",
      status: "Submitted",
      conflictStatus: "No Conflict"
    });

    const element = createElement("c-ps-deal-registration-form", {
      is: PsDealRegistrationForm
    });

    document.body.appendChild(element);

    getEligibleOpportunities.emit([
      { opportunityId: "opp-1", name: "Acme Renewal" }
    ]);
    await flushPromises();

    const combobox = element.shadowRoot.querySelector("lightning-combobox");
    combobox.dispatchEvent(
      new CustomEvent("change", { detail: { value: "opp-1" } })
    );
    await flushPromises();

    element.shadowRoot
      .querySelector("form")
      .dispatchEvent(new CustomEvent("submit", { cancelable: true }));
    await flushPromises();
    await flushPromises();

    expect(createDealRegistration).toHaveBeenCalledWith(
      expect.objectContaining({
        request: expect.objectContaining({ opportunityId: "opp-1" })
      })
    );
    expect(element.shadowRoot.querySelector(".success-card")).not.toBeNull();
  });
});
