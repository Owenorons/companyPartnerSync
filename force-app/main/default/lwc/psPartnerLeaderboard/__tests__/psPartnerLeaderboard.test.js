import { createElement } from "@lwc/engine-dom";
import PsPartnerLeaderboard from "c/psPartnerLeaderboard";
import getPartnerLeaderboard from "@salesforce/apex/AnalyticsController.getPartnerLeaderboard";

jest.mock(
  "@salesforce/apex/AnalyticsController.getPartnerLeaderboard",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-ps-partner-leaderboard", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  it("renders partners ranked by score and aggregate metrics", async () => {
    const element = createElement("c-ps-partner-leaderboard", {
      is: PsPartnerLeaderboard
    });

    document.body.appendChild(element);

    getPartnerLeaderboard.emit([
      {
        partnerAccountId: "001xx0000000001",
        partnerName: "Silver Partner",
        partnerTier: "Silver",
        partnerStatus: "Active",
        wonDeals: 1,
        revenue: 10000,
        conversionRate: 0.25,
        score: 10
      },
      {
        partnerAccountId: "001xx0000000002",
        partnerName: "Gold Partner",
        partnerTier: "Gold",
        partnerStatus: "Active",
        wonDeals: 3,
        revenue: 50000,
        conversionRate: 0.5,
        score: 90
      }
    ]);
    await flushPromises();

    const rows = element.shadowRoot.querySelectorAll(".partner-row");
    const metrics = element.shadowRoot.querySelectorAll(
      "c-ps-dashboard-metric-card"
    );

    expect(rows).toHaveLength(2);
    expect(rows[0].querySelector("h3").textContent).toBe("Gold Partner");
    expect(metrics[0].value).toBe("$60,000");
    expect(metrics[1].value).toBe(4);
  });
});
