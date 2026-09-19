import { createElement } from "@lwc/engine-dom";
import PsPartnerShareManager from "c/psPartnerShareManager";
import getActiveShares from "@salesforce/apex/PartnerShareController.getActiveShares";
import grantAccess from "@salesforce/apex/PartnerShareController.grantAccess";
import revokeAccess from "@salesforce/apex/PartnerShareController.revokeAccess";

jest.mock(
  "@salesforce/apex/PartnerShareController.getActiveShares",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PartnerShareController.grantAccess",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PartnerShareController.revokeAccess",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

function createShareManager(props = {}) {
  const element = createElement("c-ps-partner-share-manager", {
    is: PsPartnerShareManager
  });

  element.recordId = "a01xx0000000001";
  element.objectApiName = "Deal_Registration__c";
  Object.assign(element, props);

  document.body.appendChild(element);

  return element;
}

describe("c-ps-partner-share-manager", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders active shares for a supported object", async () => {
    const element = createShareManager();

    getActiveShares.emit([
      {
        shareId: "a03xx0000000001",
        partnerAccountId: "001xx0000000001",
        partnerAccountName: "Co-Sell Partner",
        accessLevel: "Edit",
        shareReason: "Co-Sell escalation",
        expiryDate: "2026-08-01",
        grantedByName: "Ada Reviewer",
        grantedOn: "2026-07-01T10:00:00.000Z"
      }
    ]);
    await flushPromises();

    expect(element.shadowRoot.querySelector(".partner-name").textContent).toBe(
      "Co-Sell Partner"
    );
    expect(element.shadowRoot.querySelector(".share-reason").textContent).toBe(
      "Co-Sell escalation"
    );
  });

  it("shows an empty state when there are no active shares", async () => {
    const element = createShareManager();

    getActiveShares.emit([]);
    await flushPromises();

    expect(
      element.shadowRoot.querySelector(".empty-state").textContent
    ).toContain("No active partner access grants");
  });

  it("does not render the manager for an unsupported object", async () => {
    const element = createShareManager({ objectApiName: "Opportunity" });

    getActiveShares.emit([]);
    await flushPromises();

    expect(
      element.shadowRoot.querySelector(".empty-state").textContent
    ).toContain("not available for this object");
    expect(
      element.shadowRoot.querySelector(".share-manager .panel-header")
    ).toBeNull();
  });

  it("grants access with the selected partner account and refreshes the list", async () => {
    grantAccess.mockResolvedValue("a03xx0000000002");

    const element = createShareManager();

    getActiveShares.emit([]);
    await flushPromises();

    element.shadowRoot.querySelector("lightning-button").click();
    await flushPromises();

    const recordPicker = element.shadowRoot.querySelector(
      "lightning-record-picker"
    );
    recordPicker.dispatchEvent(
      new CustomEvent("change", { detail: { recordId: "001xx0000000002" } })
    );

    const combobox = element.shadowRoot.querySelector("lightning-combobox");
    combobox.dispatchEvent(
      new CustomEvent("change", { detail: { value: "Read" } })
    );

    const textarea = element.shadowRoot.querySelector("lightning-textarea");
    textarea.value = "Escalation review";
    textarea.dispatchEvent(new CustomEvent("change"));
    await flushPromises();

    const grantButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Grant Access");

    expect(grantButton.disabled).toBe(false);

    grantButton.click();
    await flushPromises();

    expect(grantAccess).toHaveBeenCalledWith({
      request: expect.objectContaining({
        targetRecordId: "a01xx0000000001",
        targetObject: "Deal Registration",
        partnerAccountId: "001xx0000000002",
        accessLevel: "Read",
        shareReason: "Escalation review"
      })
    });
  });

  it("revokes an active share", async () => {
    revokeAccess.mockResolvedValue();

    const element = createShareManager();

    getActiveShares.emit([
      {
        shareId: "a03xx0000000003",
        partnerAccountId: "001xx0000000003",
        partnerAccountName: "Co-Sell Partner",
        accessLevel: "Read",
        shareReason: "Escalation",
        expiryDate: null,
        grantedByName: "Ada Reviewer",
        grantedOn: "2026-07-01T10:00:00.000Z"
      }
    ]);
    await flushPromises();

    element.shadowRoot.querySelector(".revoke-button").click();
    await flushPromises();

    expect(revokeAccess).toHaveBeenCalledWith({
      partnerRecordShareId: "a03xx0000000003"
    });
  });
});
