import { createElement } from "@lwc/engine-dom";
import PsExecutiveCommandCenter from "c/psExecutiveCommandCenter";
import getLatestSnapshot from "@salesforce/apex/ExecutiveCommandCenterController.getLatestSnapshot";
import getMetricDefinitions from "@salesforce/apex/ExecutiveCommandCenterController.getMetricDefinitions";
import getTrend from "@salesforce/apex/ExecutiveCommandCenterController.getTrend";
import exportSnapshotCsv from "@salesforce/apex/ExecutiveCommandCenterController.exportSnapshotCsv";

function mockWireAdapter() {
  const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
  return { default: createApexTestWireAdapter(jest.fn()) };
}

jest.mock(
  "@salesforce/apex/ExecutiveCommandCenterController.getLatestSnapshot",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/ExecutiveCommandCenterController.getMetricDefinitions",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/ExecutiveCommandCenterController.getTrend",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/ExecutiveCommandCenterController.exportSnapshotCsv",
  () => ({
    default: jest.fn(() =>
      Promise.resolve("Snapshot Date,Active\n2026-09-28,12")
    )
  }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

const SNAPSHOT = {
  snapshotId: "a0Xxx000000001",
  snapshotDate: "2026-09-28",
  activePartnerCount: 12,
  averageHealthScore: 68,
  totalOpenDealCount: 40,
  totalAtRiskDealCount: 3,
  totalActiveEngagementCount: 20,
  totalAtRiskEngagementCount: 2,
  totalUpcomingRenewalCount: 5,
  totalRenewalValueAtRisk: 15000,
  totalOpenExpansionCount: 4,
  totalChurnedEngagementCountTrailing12mo: 1,
  totalRevenueTrailing12mo: 250000,
  openAiRecommendationCount: 2,
  narrative: "The organisation has 12 active partners.",
  computedOn: "2026-09-28T08:00:00.000Z"
};

const METRIC_DEFINITIONS = [
  {
    Metric_Key__c: "Active_Partner_Count__c",
    Display_Label__c: "Active Partners",
    Category__c: "Health",
    Format__c: "Number",
    Display_Order__c: 1
  },
  {
    Metric_Key__c: "Total_Revenue_Trailing_12mo__c",
    Display_Label__c: "Revenue (12mo)",
    Category__c: "Revenue",
    Format__c: "Currency",
    Display_Order__c: 2
  }
];

describe("c-ps-executive-command-center", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders metric tiles and the narrative from the latest snapshot", async () => {
    const element = createElement("c-ps-executive-command-center", {
      is: PsExecutiveCommandCenter
    });
    document.body.appendChild(element);

    getLatestSnapshot.emit(SNAPSHOT);
    getMetricDefinitions.emit(METRIC_DEFINITIONS);
    getTrend.emit([SNAPSHOT]);
    await flushPromises();

    const tiles = element.shadowRoot.querySelectorAll(
      "c-ps-dashboard-metric-card"
    );
    expect(tiles).toHaveLength(2);
    expect(tiles[0].label).toBe("Active Partners");
    expect(tiles[1].value).toBe("$250,000");

    expect(
      element.shadowRoot.querySelector(".narrative-text").textContent
    ).toBe(SNAPSHOT.narrative);

    const trendCards = element.shadowRoot.querySelectorAll(".queue-card");
    expect(trendCards).toHaveLength(1);
  });

  it("exports the snapshot as a CSV download when the export button is clicked", async () => {
    global.URL.createObjectURL = jest.fn(() => "blob:mock");
    global.URL.revokeObjectURL = jest.fn();

    const element = createElement("c-ps-executive-command-center", {
      is: PsExecutiveCommandCenter
    });
    document.body.appendChild(element);

    getLatestSnapshot.emit(SNAPSHOT);
    getMetricDefinitions.emit(METRIC_DEFINITIONS);
    getTrend.emit([SNAPSHOT]);
    await flushPromises();

    element.shadowRoot.querySelector(".action-button-export").click();
    await flushPromises();

    expect(exportSnapshotCsv).toHaveBeenCalled();
    expect(global.URL.createObjectURL).toHaveBeenCalled();
    expect(global.URL.revokeObjectURL).toHaveBeenCalled();
  });

  it("shows an empty state when no snapshot has been computed yet", async () => {
    const element = createElement("c-ps-executive-command-center", {
      is: PsExecutiveCommandCenter
    });
    document.body.appendChild(element);

    getLatestSnapshot.emit(null);
    getMetricDefinitions.emit([]);
    getTrend.emit([]);
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-empty-state").title).toBe(
      "No snapshot yet"
    );
  });

  it("shows an error panel when the snapshot wire fails", async () => {
    const element = createElement("c-ps-executive-command-center", {
      is: PsExecutiveCommandCenter
    });
    document.body.appendChild(element);

    getLatestSnapshot.error({
      body: { message: "Executive analytics access denied." }
    });
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "Unable to load the executive snapshot."
    );
  });
});
