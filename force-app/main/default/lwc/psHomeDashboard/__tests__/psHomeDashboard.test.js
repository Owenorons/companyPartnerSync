import { createElement } from "@lwc/engine-dom";
import PsHomeDashboard from "c/psHomeDashboard";
import getDashboard from "@salesforce/apex/PartnerPortalController.getDashboard";

jest.mock(
  "@salesforce/apex/PartnerPortalController.getDashboard",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-ps-home-dashboard", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders labeled quick action buttons", async () => {
    const element = createElement("c-ps-home-dashboard", {
      is: PsHomeDashboard
    });

    document.body.appendChild(element);

    getDashboard.emit({
      partnerName: "Acme",
      partnerStatus: "Active",
      partnerTier: "Gold",
      openDealCount: 2,
      assignedLeadCount: 3,
      openMdfCount: 1,
      alerts: []
    });
    await flushPromises();

    const buttons = Array.from(
      element.shadowRoot.querySelectorAll(".action-button")
    );

    expect(buttons.map((button) => button.label)).toEqual([
      "Register Deal",
      "View Leads",
      "Request MDF",
      "Content Hub"
    ]);
    expect(buttons.map((button) => button.iconName)).toEqual([
      "utility:add",
      "utility:lead",
      "utility:money",
      "utility:file"
    ]);
    expect(buttons.every((button) => button.type === "button")).toBe(true);
  });
});
