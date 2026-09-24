import { createElement } from "@lwc/engine-dom";
import PsPartnerConsentPanel from "c/psPartnerConsentPanel";
import getMyConsents from "@salesforce/apex/PartnerConsentController.getMyConsents";
import acceptConsent from "@salesforce/apex/PartnerConsentController.acceptConsent";
import revokeConsent from "@salesforce/apex/PartnerConsentController.revokeConsent";

jest.mock(
  "@salesforce/apex/PartnerConsentController.getMyConsents",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PartnerConsentController.acceptConsent",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PartnerConsentController.revokeConsent",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-ps-partner-consent-panel", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("shows the accept action when no active consent is on file", async () => {
    const element = createElement("c-ps-partner-consent-panel", {
      is: PsPartnerConsentPanel
    });

    document.body.appendChild(element);
    getMyConsents.emit([]);
    await flushPromises();

    expect(element.shadowRoot.querySelector("lightning-button").label).toBe(
      "Accept"
    );
  });

  it("shows accepted status and calls revoke", async () => {
    revokeConsent.mockResolvedValue();

    const element = createElement("c-ps-partner-consent-panel", {
      is: PsPartnerConsentPanel
    });

    document.body.appendChild(element);
    getMyConsents.emit([
      {
        Id: "a04000000000001",
        Policy_Key__c: "Partner Program Terms",
        Policy_Version__c: "2026.1",
        Status__c: "Active",
        Accepted_On__c: "2026-09-24T00:00:00.000Z"
      }
    ]);
    await flushPromises();

    const button = element.shadowRoot.querySelector("lightning-button");
    expect(button.label).toBe("Revoke");

    button.click();
    await flushPromises();

    expect(revokeConsent).toHaveBeenCalledWith({
      consentId: "a04000000000001"
    });
  });

  it("accepts the configured policy", async () => {
    acceptConsent.mockResolvedValue();

    const element = createElement("c-ps-partner-consent-panel", {
      is: PsPartnerConsentPanel
    });

    document.body.appendChild(element);
    getMyConsents.emit([]);
    await flushPromises();

    element.shadowRoot.querySelector("lightning-button").click();
    await flushPromises();

    expect(acceptConsent).toHaveBeenCalledWith({
      policyKey: "Partner Program Terms",
      policyVersion: "2026.1"
    });
  });
});
