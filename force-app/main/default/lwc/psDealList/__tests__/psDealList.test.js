import { createElement } from "@lwc/engine-dom";
import PsDealList from "c/psDealList";
import getMyDeals from "@salesforce/apex/DealRegistrationController.getMyDeals";

const mockNavigate = jest.fn();

jest.mock("lightning/navigation", () => {
  const Navigate = Symbol("Navigate");

  const NavigationMixin = (Base) =>
    class extends Base {
      [Navigate](...args) {
        mockNavigate(...args);
      }
    };
  NavigationMixin.Navigate = Navigate;

  return { NavigationMixin };
});

jest.mock(
  "@salesforce/apex/DealRegistrationController.getMyDeals",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-ps-deal-list", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders deals returned from the wire", async () => {
    const element = createElement("c-ps-deal-list", { is: PsDealList });

    document.body.appendChild(element);

    getMyDeals.emit([
      {
        dealId: "a02xx0000000001",
        dealNumber: "DR-001",
        customerName: "Acme",
        status: "Submitted",
        dealValue: 25000,
        protectionEndDate: null,
        conflictStatus: "None"
      }
    ]);
    await flushPromises();

    expect(element.shadowRoot.querySelector(".deal-number").textContent).toBe(
      "DR-001"
    );
    expect(element.shadowRoot.querySelector("h2").textContent).toBe("Acme");
  });

  it("shows an empty state when there are no deals", async () => {
    const element = createElement("c-ps-deal-list", { is: PsDealList });

    document.body.appendChild(element);

    getMyDeals.emit([]);
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-empty-state")).not.toBeNull();
  });

  it("navigates to the configured Register Deal page by default", async () => {
    const element = createElement("c-ps-deal-list", { is: PsDealList });

    document.body.appendChild(element);

    getMyDeals.emit([]);
    await flushPromises();

    element.shadowRoot.querySelector("lightning-button").click();

    expect(mockNavigate).toHaveBeenCalledWith({
      type: "comm__namedPage",
      attributes: { name: "Register_Deal__c" }
    });
  });

  it("navigates to a custom Register Deal page when configured", async () => {
    const element = createElement("c-ps-deal-list", { is: PsDealList });
    element.registerDealPageName = "Custom-Register-Deal";

    document.body.appendChild(element);

    getMyDeals.emit([]);
    await flushPromises();

    element.shadowRoot.querySelector("lightning-button").click();

    expect(mockNavigate).toHaveBeenCalledWith({
      type: "comm__namedPage",
      attributes: { name: "Custom-Register-Deal" }
    });
  });

  it("does not navigate when no Register Deal page name is configured", async () => {
    const element = createElement("c-ps-deal-list", { is: PsDealList });
    element.registerDealPageName = "";

    document.body.appendChild(element);

    getMyDeals.emit([]);
    await flushPromises();

    element.shadowRoot.querySelector("lightning-button").click();

    expect(mockNavigate).not.toHaveBeenCalled();
  });
});
