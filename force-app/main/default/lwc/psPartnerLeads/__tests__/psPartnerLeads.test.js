import { createElement } from "@lwc/engine-dom";
import PsPartnerLeads from "c/psPartnerLeads";
import getMyLeads from "@salesforce/apex/LeadDistributionController.getMyLeads";
import processDecision from "@salesforce/apex/LeadDistributionController.processDecision";

jest.mock(
  "@salesforce/apex/LeadDistributionController.getMyLeads",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/LeadDistributionController.processDecision",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-ps-partner-leads", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders assigned leads and submits an accept decision", async () => {
    processDecision.mockResolvedValue();
    const element = createElement("c-ps-partner-leads", {
      is: PsPartnerLeads
    });
    document.body.appendChild(element);

    getMyLeads.emit([
      {
        leadId: "00Qxx000000001",
        company: "Acme",
        leadName: "Alex Partner",
        email: "alex@example.com",
        phone: "555-0100",
        status: "Assigned",
        slaDeadline: new Date(Date.now() + 60 * 60 * 1000).toISOString()
      }
    ]);
    await flushPromises();

    const accept = element.shadowRoot.querySelector("button.accept");
    expect(accept).not.toBeNull();
    expect(element.shadowRoot.querySelector("c-ps-status-badge").variant).toBe(
      "warning"
    );

    accept.click();
    await flushPromises();

    expect(processDecision).toHaveBeenCalledWith({
      request: {
        leadId: "00Qxx000000001",
        decision: "Accepted",
        notes: ""
      }
    });
  });

  it("emits the accepted lead for conversion", async () => {
    const element = createElement("c-ps-partner-leads", {
      is: PsPartnerLeads
    });
    const handler = jest.fn();
    element.addEventListener("convertlead", handler);
    document.body.appendChild(element);

    getMyLeads.emit([
      {
        leadId: "00Qxx000000002",
        company: "Globex",
        status: "Accepted"
      }
    ]);
    await flushPromises();

    element.shadowRoot.querySelector("button.convert").click();
    expect(handler).toHaveBeenCalled();
    expect(handler.mock.calls[0][0].detail).toEqual({
      leadId: "00Qxx000000002"
    });
  });

  it("shows server errors without leaving stale lead cards", async () => {
    const element = createElement("c-ps-partner-leads", {
      is: PsPartnerLeads
    });
    document.body.appendChild(element);

    getMyLeads.error({ body: { message: "Lead access denied." } });
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-error-panel").message).toBe(
      "Unable to load leads."
    );
    expect(element.shadowRoot.querySelectorAll(".lead-card")).toHaveLength(0);
  });
});
