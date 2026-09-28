import { createElement } from "@lwc/engine-dom";
import CustomerSuccessWorkbench from "c/customerSuccessWorkbench";
import getPendingHandoffs from "@salesforce/apex/CustomerSuccessController.getPendingHandoffs";
import getAtRiskEngagements from "@salesforce/apex/CustomerSuccessController.getAtRiskEngagements";
import getRenewalsDue from "@salesforce/apex/CustomerSuccessController.getRenewalsDue";
import getPartnerConfirmationRequired from "@salesforce/apex/CustomerSuccessController.getPartnerConfirmationRequired";
import getExpansionOpportunities from "@salesforce/apex/CustomerSuccessController.getExpansionOpportunities";
import getPendingReassignments from "@salesforce/apex/CustomerSuccessController.getPendingReassignments";
import getChurnedEngagements from "@salesforce/apex/CustomerSuccessController.getChurnedEngagements";

function mockWireAdapter() {
  const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
  return { default: createApexTestWireAdapter(jest.fn()) };
}

jest.mock(
  "@salesforce/apex/CustomerSuccessController.getPendingHandoffs",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CustomerSuccessController.getAtRiskEngagements",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CustomerSuccessController.getRenewalsDue",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CustomerSuccessController.getPartnerConfirmationRequired",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CustomerSuccessController.getExpansionOpportunities",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CustomerSuccessController.getPendingReassignments",
  () => mockWireAdapter(),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/CustomerSuccessController.getChurnedEngagements",
  () => mockWireAdapter(),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

function selectTab(element, tabName) {
  element.shadowRoot.querySelector(`button[data-tab="${tabName}"]`).click();
}

describe("c-customer-success-workbench", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders pending handoffs by default", async () => {
    const element = createElement("c-customer-success-workbench", {
      is: CustomerSuccessWorkbench
    });
    document.body.appendChild(element);

    getPendingHandoffs.emit([{ Id: "a0Mxx000000001" }]);
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("renders at-risk engagements on that tab", async () => {
    const element = createElement("c-customer-success-workbench", {
      is: CustomerSuccessWorkbench
    });
    document.body.appendChild(element);

    getAtRiskEngagements.emit([
      { Id: "a0Nxx000000001", Health_Status__c: "At Risk", Health_Score__c: 35 }
    ]);
    await flushPromises();

    selectTab(element, "atRisk");
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("renders renewals due on that tab", async () => {
    const element = createElement("c-customer-success-workbench", {
      is: CustomerSuccessWorkbench
    });
    document.body.appendChild(element);

    getRenewalsDue.emit([
      { Id: "a0Oxx000000001", Status__c: "Review Required" }
    ]);
    await flushPromises();

    selectTab(element, "renewalsDue");
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("renders renewals awaiting partner confirmation on that tab", async () => {
    const element = createElement("c-customer-success-workbench", {
      is: CustomerSuccessWorkbench
    });
    document.body.appendChild(element);

    getPartnerConfirmationRequired.emit([{ Id: "a0Pxx000000001" }]);
    await flushPromises();

    selectTab(element, "partnerConfirmation");
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("renders expansion opportunities on that tab", async () => {
    const element = createElement("c-customer-success-workbench", {
      is: CustomerSuccessWorkbench
    });
    document.body.appendChild(element);

    getExpansionOpportunities.emit([
      {
        Id: "a0Qxx000000001",
        Expansion_Type__c: "Seat Increase",
        Status__c: "Identified"
      }
    ]);
    await flushPromises();

    selectTab(element, "expansionOpportunities");
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("renders pending partner reassignments on that tab", async () => {
    const element = createElement("c-customer-success-workbench", {
      is: CustomerSuccessWorkbench
    });
    document.body.appendChild(element);

    getPendingReassignments.emit([
      {
        Id: "a0Rxx000000001",
        Target_Object__c: "Partner_Renewal__c",
        Reason__c: "Original partner exited."
      }
    ]);
    await flushPromises();

    selectTab(element, "partnerReassignment");
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("renders churned engagements on that tab", async () => {
    const element = createElement("c-customer-success-workbench", {
      is: CustomerSuccessWorkbench
    });
    document.body.appendChild(element);

    getChurnedEngagements.emit([
      { Id: "a0Sxx000000001", Churn_Category__c: "Non-Renewal" }
    ]);
    await flushPromises();

    selectTab(element, "churn");
    await flushPromises();

    expect(element.shadowRoot.querySelectorAll(".queue-card")).toHaveLength(1);
  });

  it("shows an error panel when a wire fails", async () => {
    const element = createElement("c-customer-success-workbench", {
      is: CustomerSuccessWorkbench
    });
    document.body.appendChild(element);

    getPendingHandoffs.error({
      body: { message: "Customer success access denied." }
    });
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "Unable to load pending handoffs."
    );
  });
});
