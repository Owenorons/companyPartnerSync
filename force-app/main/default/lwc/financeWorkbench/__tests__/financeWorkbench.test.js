import { createElement } from "@lwc/engine-dom";
import FinanceWorkbench from "c/financeWorkbench";
import getUnmatchedRevenue from "@salesforce/apex/RevenueController.getUnmatchedRevenue";
import getAttributionExceptions from "@salesforce/apex/RevenueController.getAttributionExceptions";
import getClaimsUnderReview from "@salesforce/apex/RevenueController.getClaimsUnderReview";
import getPaymentPending from "@salesforce/apex/RevenueController.getPaymentPending";
import getOpenDisputes from "@salesforce/apex/RevenueController.getOpenDisputes";

function mockWireAdapter() {
  const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
  return { default: createApexTestWireAdapter(jest.fn()) };
}

jest.mock(
  "@salesforce/apex/RevenueController.getUnmatchedRevenue",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/RevenueController.getAttributionExceptions",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/RevenueController.getClaimsUnderReview",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/RevenueController.getPaymentPending",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/RevenueController.getOpenDisputes",
  () => mockWireAdapter(),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

function selectTab(element, tabName) {
  element.shadowRoot.querySelector(`button[data-tab="${tabName}"]`).click();
}

describe("c-finance-workbench", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders unmatched revenue by default", async () => {
    const element = createElement("c-finance-workbench", {
      is: FinanceWorkbench
    });
    document.body.appendChild(element);

    getUnmatchedRevenue.emit([
      {
        Id: "a0Hxx000000001",
        Revenue__c: "a0Gxx000000001",
        Status__c: "Open",
        Match_Method__c: "Automatic"
      }
    ]);
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("renders attribution exceptions on that tab", async () => {
    const element = createElement("c-finance-workbench", {
      is: FinanceWorkbench
    });
    document.body.appendChild(element);

    getAttributionExceptions.emit([
      {
        Id: "a0Ixx000000001",
        Attribution_Type__c: "Sourced",
        Attribution_Percentage__c: 100
      }
    ]);
    await flushPromises();

    selectTab(element, "attributionExceptions");
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("renders claims under review on that tab", async () => {
    const element = createElement("c-finance-workbench", {
      is: FinanceWorkbench
    });
    document.body.appendChild(element);

    getClaimsUnderReview.emit([
      {
        Id: "a0Jxx000000001",
        Claimed_Amount__c: 4500,
        Status__c: "Submitted"
      }
    ]);
    await flushPromises();

    selectTab(element, "claimsUnderReview");
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("renders payments pending on that tab", async () => {
    const element = createElement("c-finance-workbench", {
      is: FinanceWorkbench
    });
    document.body.appendChild(element);

    getPaymentPending.emit([
      {
        Id: "a0Kxx000000001",
        Incentive_Type__c: "Commission",
        Approved_Amount__c: 4500,
        CurrencyIsoCode: "USD",
        Status__c: "Approved"
      }
    ]);
    await flushPromises();

    selectTab(element, "paymentPending");
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("renders open disputes on that tab", async () => {
    const element = createElement("c-finance-workbench", {
      is: FinanceWorkbench
    });
    document.body.appendChild(element);

    getOpenDisputes.emit([
      {
        Id: "a0Lxx000000001",
        Dispute_Type__c: "Missing Revenue",
        Description__c: "We sourced this deal.",
        Status__c: "Open"
      }
    ]);
    await flushPromises();

    selectTab(element, "openDisputes");
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("shows an error panel when a wire fails", async () => {
    const element = createElement("c-finance-workbench", {
      is: FinanceWorkbench
    });
    document.body.appendChild(element);

    getUnmatchedRevenue.error({
      body: { message: "Finance access denied." }
    });
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "Unable to load unmatched revenue."
    );
  });
});
