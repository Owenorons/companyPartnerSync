import { createElement } from "@lwc/engine-dom";
import PsPartnerApplicationReview from "c/psPartnerApplicationReview";
import getPendingApplications from "@salesforce/apex/PartnerApplicationController.getPendingApplications";
import getApplicationDetail from "@salesforce/apex/PartnerApplicationController.getApplicationDetail";
import processDecision from "@salesforce/apex/PartnerApprovalController.processDecision";

jest.mock(
  "@salesforce/apex/PartnerApplicationController.getPendingApplications",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PartnerApplicationController.getApplicationDetail",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PartnerApprovalController.processDecision",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

const LIST_ROW = {
  applicationId: "a03xx0000000001",
  applicationNumber: "PA-000001",
  companyName: "Acme Logistics",
  requestedTier: "Gold",
  partnerType: "Reseller",
  status: "Submitted",
  submittedOn: "2026-07-01T00:00:00.000Z"
};

const DETAIL = {
  applicationId: "a03xx0000000001",
  applicationNumber: "PA-000001",
  companyName: "Acme Logistics",
  businessEmail: "hello@acmelogistics.com",
  phone: "555-0100",
  website: "https://acmelogistics.com",
  country: "Australia",
  region: "ANZ",
  requestedTier: "Gold",
  partnerType: "Reseller",
  submittedByContactName: "Dana Whitfield",
  submittedByEmail: "dana@acmelogistics.com",
  status: "Submitted",
  decision: "Pending",
  rejectionReason: null,
  approvalNotes: null,
  isReviewable: true,
  canDecide: true
};

describe("c-ps-partner-application-review", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders the queue and auto-loads the first application's detail", async () => {
    getApplicationDetail.mockResolvedValue(DETAIL);

    const element = createElement("c-ps-partner-application-review", {
      is: PsPartnerApplicationReview
    });
    document.body.appendChild(element);

    getPendingApplications.emit([LIST_ROW]);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector(".queue-row h3").textContent).toBe(
      "Acme Logistics"
    );
    expect(getApplicationDetail).toHaveBeenCalledWith({
      applicationId: "a03xx0000000001"
    });
    expect(element.shadowRoot.querySelector(".hero-card h2").textContent).toBe(
      "Acme Logistics"
    );
    expect(element.shadowRoot.querySelector(".approve")).not.toBeNull();
  });

  it("shows the empty queue state when there are no pending applications", async () => {
    const element = createElement("c-ps-partner-application-review", {
      is: PsPartnerApplicationReview
    });
    document.body.appendChild(element);

    getPendingApplications.emit([]);
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-empty-state")).not.toBeNull();
  });

  it("submits an approve decision for the selected application", async () => {
    getApplicationDetail.mockResolvedValue(DETAIL);
    processDecision.mockResolvedValue();

    const element = createElement("c-ps-partner-application-review", {
      is: PsPartnerApplicationReview
    });
    document.body.appendChild(element);

    getPendingApplications.emit([LIST_ROW]);
    await flushPromises();
    await flushPromises();

    element.shadowRoot.querySelector(".approve").click();
    await flushPromises();

    expect(processDecision).toHaveBeenCalledWith({
      request: expect.objectContaining({
        applicationId: "a03xx0000000001",
        decision: "Approved"
      })
    });
  });

  it("requires a rejection reason before submitting a reject decision", async () => {
    getApplicationDetail.mockResolvedValue(DETAIL);
    processDecision.mockResolvedValue();

    const element = createElement("c-ps-partner-application-review", {
      is: PsPartnerApplicationReview
    });
    document.body.appendChild(element);

    getPendingApplications.emit([LIST_ROW]);
    await flushPromises();
    await flushPromises();

    element.shadowRoot.querySelector(".reject").click();
    await flushPromises();

    const textarea = element.shadowRoot.querySelector("lightning-textarea");
    let rejectButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Reject");

    expect(textarea).not.toBeNull();
    expect(rejectButton.disabled).toBe(true);

    textarea.value = "Duplicate application already under review.";
    textarea.dispatchEvent(new CustomEvent("change"));
    await flushPromises();

    rejectButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Reject");

    expect(rejectButton.disabled).toBe(false);

    rejectButton.click();
    await flushPromises();

    expect(processDecision).toHaveBeenCalledWith({
      request: expect.objectContaining({
        applicationId: "a03xx0000000001",
        decision: "Rejected",
        rejectionReason: "Duplicate application already under review."
      })
    });
  });

  it("renders the stamp for a decided application instead of action buttons", async () => {
    getApplicationDetail.mockResolvedValue({
      ...DETAIL,
      status: "Approved",
      decision: "Approved",
      isReviewable: false
    });

    const element = createElement("c-ps-partner-application-review", {
      is: PsPartnerApplicationReview
    });
    document.body.appendChild(element);

    getPendingApplications.emit([{ ...LIST_ROW, status: "Approved" }]);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector(".approve")).toBeNull();
    expect(element.shadowRoot.querySelector(".reject")).toBeNull();
    expect(element.shadowRoot.querySelector(".stamp").textContent).toBe(
      "Approved"
    );
  });
});
