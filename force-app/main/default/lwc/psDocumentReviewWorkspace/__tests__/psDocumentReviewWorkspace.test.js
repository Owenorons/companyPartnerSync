import { createElement } from "@lwc/engine-dom";
import PsDocumentReviewWorkspace from "c/psDocumentReviewWorkspace";
import getReviewQueue from "@salesforce/apex/PartnerDocumentReviewController.getReviewQueue";
import reviewDocument from "@salesforce/apex/PartnerDocumentReviewController.reviewDocument";

jest.mock(
  "@salesforce/apex/PartnerDocumentReviewController.getReviewQueue",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PartnerDocumentReviewController.reviewDocument",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

const QUEUE_ROW = {
  documentId: "a06xx0000000001",
  requirementId: "a07xx0000000001",
  onboardingId: "a05xx0000000001",
  contentDocumentId: "069xx0000000001AAA",
  partnerName: "North Partner",
  documentType: "Certificate of Incorporation",
  version: 1,
  status: "Submitted",
  confidentiality: "Partner",
  submittedOn: "2026-01-01T00:00:00.000Z"
};

describe("c-ps-document-review-workspace", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders queue rows and selects the first document", async () => {
    const element = createElement("c-ps-document-review-workspace", {
      is: PsDocumentReviewWorkspace
    });

    document.body.appendChild(element);

    getReviewQueue.emit([QUEUE_ROW]);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector(".queue-row h3").textContent).toBe(
      "North Partner"
    );
    expect(element.shadowRoot.querySelector(".hero-card h2").textContent).toBe(
      "North Partner"
    );
    expect(element.shadowRoot.querySelector(".download-link").href).toContain(
      "/sfc/servlet.shepherd/document/download/069xx0000000001AAA"
    );
  });

  it("submits a decision for the selected document and refreshes the queue", async () => {
    reviewDocument.mockResolvedValue();

    const element = createElement("c-ps-document-review-workspace", {
      is: PsDocumentReviewWorkspace
    });

    document.body.appendChild(element);

    getReviewQueue.emit([QUEUE_ROW]);
    await flushPromises();
    await flushPromises();

    const submitButton = element.shadowRoot.querySelector("lightning-button");
    submitButton.click();
    await flushPromises();
    await flushPromises();

    expect(reviewDocument).toHaveBeenCalledWith({
      request: {
        documentId: "a06xx0000000001",
        outcome: "Accepted",
        reason: ""
      }
    });
  });

  it("shows an already-decided message for a document that cannot be decided", async () => {
    const element = createElement("c-ps-document-review-workspace", {
      is: PsDocumentReviewWorkspace
    });

    document.body.appendChild(element);

    getReviewQueue.emit([{ ...QUEUE_ROW, status: "Accepted" }]);
    await flushPromises();
    await flushPromises();

    expect(
      element.shadowRoot.querySelector(".decision-state").textContent
    ).toContain("already been decided");
    expect(
      element.shadowRoot.querySelectorAll("lightning-combobox").length
    ).toBe(1);
  });
});
