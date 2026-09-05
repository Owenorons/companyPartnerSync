import { createElement } from "@lwc/engine-dom";
import PsSetupHealthCheck from "c/psSetupHealthCheck";
import getReadiness from "@salesforce/apex/PartnerSyncSetupController.getReadiness";
import configureOperationalAutomation from "@salesforce/apex/PartnerSyncSetupController.configureOperationalAutomation";

jest.mock(
  "@salesforce/apex/PartnerSyncSetupController.getReadiness",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/PartnerSyncSetupController.configureOperationalAutomation",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

const REPORT = {
  generatedAt: "2026-08-22T01:00:00.000Z",
  readyCount: 4,
  totalCount: 6,
  coreReady: true,
  portalReady: false,
  checks: [
    {
      key: "core-metadata",
      label: "Core application",
      status: "READY",
      detail: "Required metadata is installed.",
      action: "No action required."
    },
    {
      key: "experience-cloud",
      label: "Experience Cloud portal",
      status: "WARNING",
      detail: "No live site was detected.",
      action: "Create and publish the site."
    }
  ]
};

describe("c-ps-setup-health-check", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("shows separate core and portal readiness", async () => {
    getReadiness.mockResolvedValue(REPORT);
    const element = createElement("c-ps-setup-health-check", {
      is: PsSetupHealthCheck
    });

    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    const badges = element.shadowRoot.querySelectorAll("lightning-badge");
    expect(badges[0].label).toBe("Core ready");
    expect(badges[1].label).toBe("Portal not ready");
    expect(element.shadowRoot.querySelectorAll(".check-item")).toHaveLength(2);
  });

  it("runs the diagnostics again", async () => {
    getReadiness.mockResolvedValue(REPORT);
    const element = createElement("c-ps-setup-health-check", {
      is: PsSetupHealthCheck
    });

    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    element.shadowRoot.querySelector("lightning-button").click();
    await flushPromises();
    await flushPromises();

    expect(getReadiness).toHaveBeenCalledTimes(2);
  });

  it("shows an actionable server error", async () => {
    getReadiness.mockRejectedValue({
      body: { message: "Assign the PartnerSync Internal Admin permission set." }
    });
    const element = createElement("c-ps-setup-health-check", {
      is: PsSetupHealthCheck
    });

    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "Assign the PartnerSync Internal Admin permission set."
    );
  });

  it("configures missing operational jobs from the setup page", async () => {
    const missingJobsReport = {
      ...REPORT,
      checks: [
        ...REPORT.checks,
        {
          key: "scheduled-automation",
          label: "Operational automation",
          status: "ACTION_REQUIRED",
          detail: "Missing jobs.",
          action: "Configure jobs."
        }
      ]
    };
    const readyReport = {
      ...missingJobsReport,
      checks: missingJobsReport.checks.map((check) => {
        if (check.key === "scheduled-automation") {
          return { ...check, status: "READY" };
        }
        return check;
      })
    };
    getReadiness.mockResolvedValue(missingJobsReport);
    configureOperationalAutomation.mockResolvedValue(readyReport);
    const element = createElement("c-ps-setup-health-check", {
      is: PsSetupHealthCheck
    });
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    element.shadowRoot
      .querySelector(".automation-action lightning-button")
      .click();
    await flushPromises();
    await flushPromises();

    expect(configureOperationalAutomation).toHaveBeenCalledTimes(1);
    expect(element.shadowRoot.querySelector(".automation-action")).toBeNull();
  });
});
