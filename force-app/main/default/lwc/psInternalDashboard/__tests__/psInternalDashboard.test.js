import { createElement } from "@lwc/engine-dom";
import PsInternalDashboard from "c/psInternalDashboard";
import getDashboard from "@salesforce/apex/InternalPortalController.getDashboard";
import acknowledgeOperationalAlert from "@salesforce/apex/InternalPortalController.acknowledgeOperationalAlert";
import transitionOperationalAlert from "@salesforce/apex/InternalPortalController.transitionOperationalAlert";

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

jest.mock(
  "@salesforce/apex/InternalPortalController.acknowledgeOperationalAlert",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/InternalPortalController.transitionOperationalAlert",
  () => ({ default: jest.fn() }),
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
      "Partner 360",
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
    expect(
      element.shadowRoot.querySelector(".alerts c-ps-empty-state")
    ).toBeNull();
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

  it("renders onboarding health metrics and operations queue", async () => {
    const element = createElement("c-ps-internal-dashboard", {
      is: PsInternalDashboard
    });
    document.body.appendChild(element);
    getDashboard.emit({
      userName: "Jordan Reviewer",
      pendingDealReviewCount: 0,
      pendingMdfReviewCount: 0,
      unreadNotificationCount: 0,
      blockedOnboardingCount: 2,
      onboardingWorkCount: 1,
      provisioningFailureCount: 1,
      recertificationDueCount: 0,
      totalOnboardingCount: 20,
      activeOnboardingCount: 12,
      onboardingCompletionRate: 0.6,
      averageActivationDays: 8.5,
      overdueOnboardingTaskCount: 3,
      onboardingBottleneckStage: "Due Diligence",
      onboardingBottleneckCount: 4,
      onboardingWorkItems: [
        {
          recordId: "a01000000000001",
          onboardingId: "a02000000000001",
          queueType: "Provisioning",
          title: "ProvisioningFailed",
          status: "Failed",
          priority: "High"
        }
      ],
      alerts: []
    });
    await flushPromises();

    const metrics = element.shadowRoot.querySelectorAll(
      ".onboarding-metrics c-ps-dashboard-metric-card"
    );
    expect(metrics).toHaveLength(4);
    expect(metrics[0].value).toBe(2);
    const table = element.shadowRoot.querySelector("lightning-datatable");
    expect(table).not.toBeNull();
    expect(table.data).toHaveLength(1);

    const outcomes = element.shadowRoot.querySelectorAll(
      ".outcome-grid c-ps-dashboard-metric-card"
    );
    expect(outcomes).toHaveLength(5);
    expect(outcomes[2].value).toBe("60%");
    expect(outcomes[3].value).toBe("8.5 days");
    expect(
      element.shadowRoot.querySelector(".bottleneck-callout").textContent
    ).toContain("Due Diligence (4)");
  });

  it("renders and filters the unified cross-domain work queue", async () => {
    const element = createElement("c-ps-internal-dashboard", {
      is: PsInternalDashboard
    });
    document.body.appendChild(element);
    getDashboard.emit({
      userName: "Jordan Reviewer",
      alerts: [],
      unifiedWorkCount: 2,
      unifiedWorkItems: [
        {
          recordId: "a1",
          domain: "Deals",
          workType: "Deal Review",
          title: "DR-1",
          priority: "High",
          status: "Submitted"
        },
        {
          recordId: "a2",
          domain: "Events",
          workType: "Dead Letter",
          title: "Event failure",
          priority: "Critical",
          status: "New"
        }
      ]
    });
    await flushPromises();
    const domainFilter = element.shadowRoot.querySelector(
      '[data-filter="workDomainFilter"]'
    );
    domainFilter.dispatchEvent(
      new CustomEvent("change", { detail: { value: "Events" } })
    );
    await flushPromises();
    const table = element.shadowRoot.querySelector(
      ".unified-workspace lightning-datatable"
    );
    expect(table.data).toHaveLength(1);
    expect(table.data[0].domain).toBe("Events");
  });

  it("renders partner evidence compliance risks", async () => {
    const element = createElement("c-ps-internal-dashboard", {
      is: PsInternalDashboard
    });
    document.body.appendChild(element);
    getDashboard.emit({
      userName: "Jordan Reviewer",
      alerts: [],
      expiredEvidenceCount: 1,
      expiringEvidenceCount: 2,
      overdueRequirementCount: 3,
      complianceItems: [
        {
          recordId: "a1",
          onboardingId: "a2",
          category: "Expired Evidence",
          documentType: "Insurance Certificate",
          severity: "Critical",
          status: "Expired",
          dueOn: "2026-08-01",
          message: "Replacement evidence is required."
        }
      ]
    });
    await flushPromises();

    const metrics = element.shadowRoot.querySelectorAll(
      ".compliance-metrics c-ps-dashboard-metric-card"
    );
    expect(metrics).toHaveLength(3);
    expect(metrics[0].value).toBe(1);
    const table = element.shadowRoot.querySelector(
      ".compliance-workspace lightning-datatable"
    );
    expect(table.data[0].severity).toBe("Critical");
  });

  it("renders and acknowledges operational alerts", async () => {
    acknowledgeOperationalAlert.mockResolvedValue();
    transitionOperationalAlert.mockResolvedValue();
    const element = createElement("c-ps-internal-dashboard", {
      is: PsInternalDashboard
    });
    document.body.appendChild(element);
    getDashboard.emit({
      userName: "Jordan Reviewer",
      pendingDealReviewCount: 0,
      pendingMdfReviewCount: 0,
      unreadNotificationCount: 0,
      alerts: [],
      openOperationalAlertCount: 1,
      operationalAlerts: [
        {
          recordId: "a03000000000001",
          alertType: "Provisioning Failure",
          severity: "High",
          status: "Open",
          message: "Failed",
          occurrenceCount: 2,
          canAcknowledge: true,
          transitionLabel: "Resolve",
          lastDetectedOn: "2026-08-06T10:00:00.000Z"
        }
      ]
    });
    await flushPromises();
    const tables = element.shadowRoot.querySelectorAll("lightning-datatable");
    const alertTable = tables[tables.length - 1];
    expect(alertTable.data).toHaveLength(1);
    alertTable.dispatchEvent(
      new CustomEvent("rowaction", {
        detail: { action: { name: "acknowledge" }, row: alertTable.data[0] }
      })
    );
    await flushPromises();
    expect(acknowledgeOperationalAlert).toHaveBeenCalledWith({
      alertId: "a03000000000001"
    });
    alertTable.dispatchEvent(
      new CustomEvent("rowaction", {
        detail: { action: { name: "transition" }, row: alertTable.data[0] }
      })
    );
    await flushPromises();
    expect(transitionOperationalAlert).toHaveBeenCalledWith({
      alertId: "a03000000000001",
      actionName: "resolve"
    });
  });

  it("filters operational alerts by status", async () => {
    const element = createElement("c-ps-internal-dashboard", {
      is: PsInternalDashboard
    });
    document.body.appendChild(element);
    getDashboard.emit({
      userName: "Jordan",
      alerts: [],
      openOperationalAlertCount: 1,
      operationalAlerts: [
        {
          recordId: "a1",
          alertType: "Overdue Work",
          severity: "High",
          status: "Open",
          lastDetectedOn: "2026-08-06T10:00:00.000Z"
        },
        {
          recordId: "a2",
          alertType: "Signature Event Failure",
          severity: "Critical",
          status: "Resolved",
          lastDetectedOn: "2026-08-05T10:00:00.000Z"
        }
      ]
    });
    await flushPromises();
    const statusFilter = element.shadowRoot.querySelector(
      '[data-filter="alertStatusFilter"]'
    );
    statusFilter.dispatchEvent(
      new CustomEvent("change", { detail: { value: "Resolved" } })
    );
    await flushPromises();
    const tables = element.shadowRoot.querySelectorAll("lightning-datatable");
    const alertTable = tables[tables.length - 1];
    expect(alertTable.data).toHaveLength(1);
    expect(alertTable.data[0].status).toBe("Resolved");
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
