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

  it("renders each alert as a list item when alerts exist", async () => {
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
      alerts: ["2 leads are awaiting your response."]
    });
    await flushPromises();

    const alertRows = element.shadowRoot.querySelectorAll(".alert-row");
    expect(alertRows).toHaveLength(1);
    expect(alertRows[0].textContent).toContain(
      "2 leads are awaiting your response."
    );
    expect(element.shadowRoot.querySelector("c-ps-empty-state")).toBeNull();
  });

  it("shows the empty state when there are no alerts", async () => {
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

    expect(element.shadowRoot.querySelector("c-ps-empty-state")).not.toBeNull();
    expect(element.shadowRoot.querySelector(".alert-row")).toBeNull();
  });
});
