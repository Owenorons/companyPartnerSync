import { createElement } from "@lwc/engine-dom";
import PsPartnerKpiDashboard from "c/psPartnerKpiDashboard";
import getMyKPI from "@salesforce/apex/AnalyticsController.getMyKPI";

jest.mock(
  "@salesforce/apex/AnalyticsController.getMyKPI",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

const KPI = {
  totalPipeline: 200000,
  totalRevenue: 110000,
  leadConversionRate: 0.42,
  dealWinRate: 0.35,
  mdfUtilisationRate: 0.7,
  healthScore: 72,
  healthLabel: "Healthy",
  recommendedTier: "Platinum",
  healthSignals: [
    "80% lead acceptance contributes up to 20 points.",
    "42% lead conversion contributes up to 25 points."
  ]
};

describe("c-ps-partner-kpi-dashboard", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders an explainable score and tier recommendation", async () => {
    const element = createElement("c-ps-partner-kpi-dashboard", {
      is: PsPartnerKpiDashboard
    });
    document.body.appendChild(element);

    getMyKPI.emit(KPI);
    await flushPromises();

    expect(
      element.shadowRoot.querySelector(".score-ring strong").textContent
    ).toBe("72/100");
    expect(
      element.shadowRoot.querySelector(".score-context strong").textContent
    ).toBe("Platinum");
    expect(element.shadowRoot.querySelectorAll(".explanation li")).toHaveLength(
      2
    );
  });

  it("renders actionable server errors", async () => {
    const element = createElement("c-ps-partner-kpi-dashboard", {
      is: PsPartnerKpiDashboard
    });
    document.body.appendChild(element);

    getMyKPI.error({ message: "Analytics is disabled." });
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "Analytics is disabled."
    );
  });
});
