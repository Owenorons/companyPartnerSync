import { createElement } from "@lwc/engine-dom";
import PartnerRevenueWorkspace from "c/partnerRevenueWorkspace";
import getRevenueSummaries from "@salesforce/apex/RevenueController.getRevenueSummaries";
import getIncentiveSummaries from "@salesforce/apex/RevenueController.getIncentiveSummaries";
import submitClaim from "@salesforce/apex/RevenueController.submitClaim";
import openDispute from "@salesforce/apex/RevenueController.openDispute";

jest.mock(
  "@salesforce/apex/RevenueController.getRevenueSummaries",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/RevenueController.getIncentiveSummaries",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/RevenueController.submitClaim",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/RevenueController.openDispute",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

const REVENUE = [
  {
    revenueId: "a0Fxx000000001",
    dealId: "a0Bxx000000001",
    revenueType: "Booking",
    status: "Confirmed",
    netAmount: 50000,
    currencyIsoCode: "USD",
    revenueDate: "2026-01-01"
  }
];

const INCENTIVES_CLAIM_REQUIRED = [
  {
    incentiveId: "a0Gxx000000001",
    dealId: "a0Bxx000000001",
    incentiveType: "Commission",
    status: "Claim Required",
    calculatedAmount: 2500,
    currencyIsoCode: "USD"
  }
];

describe("c-partner-revenue-workspace", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders revenue and incentives", async () => {
    const element = createElement("c-partner-revenue-workspace", {
      is: PartnerRevenueWorkspace
    });
    element.recordId = "a0Bxx000000001";
    document.body.appendChild(element);

    getRevenueSummaries.emit(REVENUE);
    await flushPromises();
    getIncentiveSummaries.emit(INCENTIVES_CLAIM_REQUIRED);
    await flushPromises();

    expect(element.shadowRoot.textContent).toContain("Booking");
    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(2);
    expect(element.shadowRoot.querySelector("button.accept")).not.toBeNull();
  });

  it("submits a claim for an incentive that requires one", async () => {
    submitClaim.mockResolvedValue();
    const element = createElement("c-partner-revenue-workspace", {
      is: PartnerRevenueWorkspace
    });
    element.recordId = "a0Bxx000000001";
    document.body.appendChild(element);

    getRevenueSummaries.emit(REVENUE);
    await flushPromises();
    getIncentiveSummaries.emit(INCENTIVES_CLAIM_REQUIRED);
    await flushPromises();

    element.shadowRoot.querySelector("button.accept").click();
    await flushPromises();

    expect(submitClaim).toHaveBeenCalledWith({
      command: {
        incentiveId: "a0Gxx000000001"
      }
    });
  });

  it("opens a dispute for a revenue row without needing its own partner account id", async () => {
    openDispute.mockResolvedValue();
    const element = createElement("c-partner-revenue-workspace", {
      is: PartnerRevenueWorkspace
    });
    element.recordId = "a0Bxx000000001";
    document.body.appendChild(element);

    getRevenueSummaries.emit(REVENUE);
    await flushPromises();
    getIncentiveSummaries.emit([]);
    await flushPromises();

    element.shadowRoot.querySelector("button.dispute").click();
    await flushPromises();

    expect(openDispute).toHaveBeenCalledWith({
      command: {
        dealId: "a0Bxx000000001",
        revenueId: "a0Fxx000000001",
        disputeType: "Missing Revenue",
        description: "Raised from the partner revenue workspace."
      }
    });
  });

  it("shows an empty state when there is no revenue yet", async () => {
    const element = createElement("c-partner-revenue-workspace", {
      is: PartnerRevenueWorkspace
    });
    element.recordId = "a0Bxx000000001";
    document.body.appendChild(element);

    getRevenueSummaries.emit([]);
    await flushPromises();
    getIncentiveSummaries.emit([]);
    await flushPromises();

    expect(
      element.shadowRoot.querySelectorAll("c-ps-empty-state")
    ).toHaveLength(2);
  });

  it("shows an error panel when the revenue wire fails", async () => {
    const element = createElement("c-partner-revenue-workspace", {
      is: PartnerRevenueWorkspace
    });
    element.recordId = "a0Bxx000000001";
    document.body.appendChild(element);

    getRevenueSummaries.error({
      message: "This deal is not accessible."
    });
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "This deal is not accessible."
    );
  });
});
