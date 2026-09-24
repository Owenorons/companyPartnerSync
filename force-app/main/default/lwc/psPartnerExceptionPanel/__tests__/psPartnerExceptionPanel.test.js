import { createElement } from "@lwc/engine-dom";
import PsPartnerExceptionPanel from "c/psPartnerExceptionPanel";
import getExceptions from "@salesforce/apex/PartnerReadinessLifecycleController.getExceptions";
import grantException from "@salesforce/apex/PartnerReadinessLifecycleController.grantException";
import revokeException from "@salesforce/apex/PartnerReadinessLifecycleController.revokeException";

jest.mock(
  "@salesforce/apex/PartnerReadinessLifecycleController.getExceptions",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PartnerReadinessLifecycleController.grantException",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PartnerReadinessLifecycleController.revokeException",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-ps-partner-exception-panel", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("shows an empty state when no exceptions exist", async () => {
    const element = createElement("c-ps-partner-exception-panel", {
      is: PsPartnerExceptionPanel
    });
    element.targetOnboardingId = "a01000000000001";

    document.body.appendChild(element);
    getExceptions.emit([]);
    await flushPromises();

    expect(element.shadowRoot.querySelector(".empty-copy").textContent).toBe(
      "No exceptions granted for this onboarding."
    );
  });

  it("grants an exception with the entered form values", async () => {
    grantException.mockResolvedValue();

    const element = createElement("c-ps-partner-exception-panel", {
      is: PsPartnerExceptionPanel
    });
    element.targetOnboardingId = "a01000000000001";

    document.body.appendChild(element);
    getExceptions.emit([]);
    await flushPromises();

    const textarea = element.shadowRoot.querySelector("lightning-textarea");
    textarea.value = "Training platform outage.";
    textarea.dispatchEvent(
      new CustomEvent("change", {
        detail: { value: "Training platform outage." }
      })
    );

    const grantButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Grant Exception");
    grantButton.click();
    await flushPromises();

    expect(grantException).toHaveBeenCalledWith(
      expect.objectContaining({
        request: expect.objectContaining({
          onboardingId: "a01000000000001",
          gate: "documents",
          reason: "Training platform outage."
        })
      })
    );
  });

  it("revokes an active exception using the entered reason", async () => {
    revokeException.mockResolvedValue();

    const element = createElement("c-ps-partner-exception-panel", {
      is: PsPartnerExceptionPanel
    });
    element.targetOnboardingId = "a01000000000001";

    document.body.appendChild(element);
    getExceptions.emit([
      {
        Id: "a02000000000001",
        Gate__c: "training",
        Status__c: "Active",
        Reason__c: "Training platform outage."
      }
    ]);
    await flushPromises();

    const textarea = element.shadowRoot.querySelector("lightning-textarea");
    textarea.value = "Training platform restored.";
    textarea.dispatchEvent(
      new CustomEvent("change", {
        detail: { value: "Training platform restored." }
      })
    );

    const revokeButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Revoke");
    revokeButton.click();
    await flushPromises();

    expect(revokeException).toHaveBeenCalledWith({
      exceptionId: "a02000000000001",
      reason: "Training platform restored."
    });
  });
});
