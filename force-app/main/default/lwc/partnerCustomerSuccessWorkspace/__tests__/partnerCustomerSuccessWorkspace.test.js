import { createElement } from "@lwc/engine-dom";
import PartnerCustomerSuccessWorkspace from "c/partnerCustomerSuccessWorkspace";
import getMyEngagements from "@salesforce/apex/CustomerSuccessController.getMyEngagements";
import getMyRenewals from "@salesforce/apex/CustomerSuccessController.getMyRenewals";
import confirmRenewal from "@salesforce/apex/CustomerSuccessController.confirmRenewal";
import declineRenewal from "@salesforce/apex/CustomerSuccessController.declineRenewal";

function mockWireAdapter() {
  const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
  return { default: createApexTestWireAdapter(jest.fn()) };
}

jest.mock(
  "@salesforce/apex/CustomerSuccessController.getMyEngagements",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CustomerSuccessController.getMyRenewals",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CustomerSuccessController.confirmRenewal",
  () => ({ default: jest.fn(() => Promise.resolve({})) }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CustomerSuccessController.declineRenewal",
  () => ({ default: jest.fn(() => Promise.resolve({})) }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-partner-customer-success-workspace", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders engagements and renewals", async () => {
    const element = createElement("c-partner-customer-success-workspace", {
      is: PartnerCustomerSuccessWorkspace
    });
    document.body.appendChild(element);

    getMyEngagements.emit([
      {
        engagementId: "a0Txx000000001",
        status: "Active",
        healthStatus: "Healthy"
      }
    ]);
    getMyRenewals.emit([
      {
        renewalId: "a0Uxx000000001",
        status: "Partner Confirmation Required",
        targetDecisionOn: "2027-01-01",
        versionNumber: 0
      }
    ]);
    await flushPromises();

    const cards = element.shadowRoot.querySelectorAll(".queue-card");
    expect(cards.length).toBe(2);
  });

  it("shows confirm/decline actions only for renewals awaiting partner confirmation", async () => {
    const element = createElement("c-partner-customer-success-workspace", {
      is: PartnerCustomerSuccessWorkspace
    });
    document.body.appendChild(element);

    getMyEngagements.emit([]);
    getMyRenewals.emit([
      {
        renewalId: "a0Uxx000000002",
        status: "Approved",
        targetDecisionOn: "2027-01-01",
        versionNumber: 0
      }
    ]);
    await flushPromises();

    expect(
      element.shadowRoot.querySelector(".action-button-confirm")
    ).toBeNull();
  });

  it("confirms a renewal when the confirm button is clicked", async () => {
    const element = createElement("c-partner-customer-success-workspace", {
      is: PartnerCustomerSuccessWorkspace
    });
    document.body.appendChild(element);

    getMyEngagements.emit([]);
    getMyRenewals.emit([
      {
        renewalId: "a0Uxx000000003",
        status: "Partner Confirmation Required",
        targetDecisionOn: "2027-01-01",
        versionNumber: 0
      }
    ]);
    await flushPromises();

    element.shadowRoot.querySelector(".action-button-confirm").click();
    await flushPromises();

    expect(confirmRenewal).toHaveBeenCalledWith({
      command: { renewalId: "a0Uxx000000003", expectedVersion: 0 }
    });
  });

  it("declines a renewal when the decline button is clicked", async () => {
    const element = createElement("c-partner-customer-success-workspace", {
      is: PartnerCustomerSuccessWorkspace
    });
    document.body.appendChild(element);

    getMyEngagements.emit([]);
    getMyRenewals.emit([
      {
        renewalId: "a0Uxx000000004",
        status: "Partner Confirmation Required",
        targetDecisionOn: "2027-01-01",
        versionNumber: 0
      }
    ]);
    await flushPromises();

    element.shadowRoot.querySelector(".action-button-decline").click();
    await flushPromises();

    expect(declineRenewal).toHaveBeenCalledWith({
      command: { renewalId: "a0Uxx000000004", expectedVersion: 0 }
    });
  });

  it("shows an error panel when a wire fails", async () => {
    const element = createElement("c-partner-customer-success-workspace", {
      is: PartnerCustomerSuccessWorkspace
    });
    document.body.appendChild(element);

    getMyEngagements.error({
      body: { message: "Customer success access denied." }
    });
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "Unable to load your customer success engagements."
    );
  });
});
