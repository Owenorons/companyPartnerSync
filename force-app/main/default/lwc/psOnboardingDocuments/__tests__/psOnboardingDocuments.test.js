import { createElement } from "@lwc/engine-dom";
import PsOnboardingDocuments from "c/psOnboardingDocuments";
import getMyRequirements from "@salesforce/apex/PartnerDocumentController.getMyRequirements";
import submitDocument from "@salesforce/apex/PartnerDocumentController.submitDocument";

jest.mock(
  "@salesforce/apex/PartnerDocumentController.getMyRequirements",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return {
      default: createApexTestWireAdapter(jest.fn())
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PartnerDocumentController.submitDocument",
  () => ({
    default: jest.fn()
  }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

const REQUIREMENT_ROW = {
  requirementId: "a07xx0000000001",
  documentType: "Certificate of Incorporation",
  requirementLevel: "Mandatory",
  status: "Awaiting Submission",
  blocking: true,
  dueOn: "2026-06-01",
  latestDocumentId: null,
  latestVersion: null,
  latestDocumentStatus: null,
  submittedOn: null
};

describe("c-ps-onboarding-documents", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders requirement rows and selects the first one", async () => {
    const element = createElement("c-ps-onboarding-documents", {
      is: PsOnboardingDocuments
    });

    document.body.appendChild(element);

    getMyRequirements.emit([REQUIREMENT_ROW]);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector(".queue-row h3").textContent).toBe(
      "Certificate of Incorporation"
    );
    expect(element.shadowRoot.querySelector(".hero-card h2").textContent).toBe(
      "Certificate of Incorporation"
    );
    expect(
      element.shadowRoot.querySelector("lightning-file-upload")
    ).not.toBeNull();
  });

  it("submits the uploaded document for the selected requirement", async () => {
    submitDocument.mockResolvedValue();

    const element = createElement("c-ps-onboarding-documents", {
      is: PsOnboardingDocuments
    });

    document.body.appendChild(element);

    getMyRequirements.emit([REQUIREMENT_ROW]);
    await flushPromises();
    await flushPromises();

    const fileUpload = element.shadowRoot.querySelector(
      "lightning-file-upload"
    );
    fileUpload.dispatchEvent(
      new CustomEvent("uploadfinished", {
        detail: {
          files: [{ documentId: "069xx0000000009AAA", name: "evidence.pdf" }]
        }
      })
    );
    await flushPromises();
    await flushPromises();

    expect(submitDocument).toHaveBeenCalledWith({
      request: {
        requirementId: "a07xx0000000001",
        contentDocumentId: "069xx0000000009AAA"
      }
    });
  });

  it("hides the upload control once the requirement is accepted", async () => {
    const element = createElement("c-ps-onboarding-documents", {
      is: PsOnboardingDocuments
    });

    document.body.appendChild(element);

    getMyRequirements.emit([
      {
        ...REQUIREMENT_ROW,
        status: "Accepted",
        latestDocumentId: "a06xx0000000002",
        latestVersion: 1,
        latestDocumentStatus: "Accepted",
        submittedOn: "2026-01-01T00:00:00.000Z"
      }
    ]);
    await flushPromises();
    await flushPromises();

    expect(
      element.shadowRoot.querySelector("lightning-file-upload")
    ).toBeNull();
    expect(
      element.shadowRoot.querySelector(".decision-state").textContent
    ).toContain("already been accepted");
  });
});
