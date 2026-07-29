import { createElement } from "@lwc/engine-dom";
import PsInternalDashboard from "c/psInternalDashboard";
import getDashboard from "@salesforce/apex/InternalPortalController.getDashboard";

jest.mock(
  "@salesforce/apex/InternalPortalController.getDashboard",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-ps-internal-dashboard", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders labeled quick action buttons", async () => {
    const element = createElement("c-ps-internal-dashboard", {
      is: PsInternalDashboard
    });

    document.body.appendChild(element);

    getDashboard.emit({
      userName: "Jordan Reviewer",
      pendingDealReviewCount: 2,
      pendingMdfReviewCount: 1,
      unreadNotificationCount: 3,
      alerts: []
    });
    await flushPromises();

    const buttons = Array.from(
      element.shadowRoot.querySelectorAll(".action-button")
    );

    expect(buttons.map((button) => button.label)).toEqual([
      "Review Deals",
      "Review MDF",
      "Notifications",
      "Manage Content"
    ]);
    expect(buttons.every((button) => button.type === "button")).toBe(true);
  });

  it("renders each alert as a list item when alerts exist", async () => {
    const element = createElement("c-ps-internal-dashboard", {
      is: PsInternalDashboard
    });

    document.body.appendChild(element);

    getDashboard.emit({
      userName: "Jordan Reviewer",
      pendingDealReviewCount: 2,
      pendingMdfReviewCount: 1,
      unreadNotificationCount: 3,
      alerts: ["2 deal registrations are awaiting review."]
    });
    await flushPromises();

    const alertRows = element.shadowRoot.querySelectorAll(".alert-row");
    expect(alertRows).toHaveLength(1);
    expect(alertRows[0].textContent).toContain(
      "2 deal registrations are awaiting review."
    );
    expect(element.shadowRoot.querySelector("c-ps-empty-state")).toBeNull();
  });

  it("shows the empty state when there are no alerts", async () => {
    const element = createElement("c-ps-internal-dashboard", {
      is: PsInternalDashboard
    });

    document.body.appendChild(element);

    getDashboard.emit({
      userName: "Jordan Reviewer",
      pendingDealReviewCount: 0,
      pendingMdfReviewCount: 0,
      unreadNotificationCount: 0,
      alerts: []
    });
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-empty-state")).not.toBeNull();
    expect(element.shadowRoot.querySelector(".alert-row")).toBeNull();
  });

  it("shows an error panel when the wire adapter errors", async () => {
    const element = createElement("c-ps-internal-dashboard", {
      is: PsInternalDashboard
    });

    document.body.appendChild(element);

    getDashboard.error({ message: "Only internal users can view this." });
    await flushPromises();

    const errorPanel = element.shadowRoot.querySelector("c-ps-error-panel");
    expect(errorPanel).not.toBeNull();
    expect(errorPanel.message).toBe("Only internal users can view this.");
  });
});
