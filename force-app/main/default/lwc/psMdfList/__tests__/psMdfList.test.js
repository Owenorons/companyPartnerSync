import { createElement } from "@lwc/engine-dom";
import PsMdfList from "c/psMdfList";
import getMyRequests from "@salesforce/apex/MDFController.getMyRequests";
import resubmitRequest from "@salesforce/apex/MDFController.resubmitRequest";

jest.mock(
  "@salesforce/apex/MDFController.getMyRequests",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/MDFController.resubmitRequest",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

describe("c-ps-mdf-list", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders MDF requests once loaded", async () => {
    getMyRequests.mockResolvedValue([
      {
        requestId: "a01xx0000000001",
        requestNumber: "MDF-000001",
        campaignName: "Spring Webinar",
        requestType: "Webinar",
        requestedAmount: 5000,
        approvedAmount: 5000,
        status: "Approved"
      }
    ]);

    const element = createElement("c-ps-mdf-list", { is: PsMdfList });
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    const items = element.shadowRoot.querySelectorAll(".request-item");
    expect(items).toHaveLength(1);
    expect(items[0].querySelector("h3").textContent).toBe("Spring Webinar");
    expect(element.shadowRoot.querySelector("c-ps-empty-state")).toBeNull();
  });

  it("shows the empty state when there are no requests", async () => {
    getMyRequests.mockResolvedValue([]);

    const element = createElement("c-ps-mdf-list", { is: PsMdfList });
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-empty-state")).not.toBeNull();
  });

  it("shows an error panel when the Apex call fails", async () => {
    getMyRequests.mockRejectedValue({
      body: { message: "Unable to load MDF requests." }
    });

    const element = createElement("c-ps-mdf-list", { is: PsMdfList });
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    const errorPanel = element.shadowRoot.querySelector("c-ps-error-panel");
    expect(errorPanel).not.toBeNull();
    expect(errorPanel.message).toBe("Unable to load MDF requests.");
  });

  it("reloads when refreshToken changes", async () => {
    getMyRequests.mockResolvedValue([]);

    const element = createElement("c-ps-mdf-list", { is: PsMdfList });
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    expect(getMyRequests).toHaveBeenCalledTimes(1);

    element.refreshToken = Date.now();
    await flushPromises();
    await flushPromises();

    expect(getMyRequests).toHaveBeenCalledTimes(2);
  });

  it("shows a resubmit action with the return reason for requests needing information", async () => {
    getMyRequests.mockResolvedValue([
      {
        requestId: "a01xx0000000002",
        requestNumber: "MDF-000002",
        campaignName: "Fall Roadshow",
        requestType: "Event",
        requestedAmount: 3000,
        approvedAmount: null,
        status: "Needs Information",
        returnReason: "Please attach a revised budget breakdown."
      }
    ]);

    const element = createElement("c-ps-mdf-list", { is: PsMdfList });
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    const notice = element.shadowRoot.querySelector(".return-notice");
    expect(notice).not.toBeNull();
    expect(notice.querySelector(".return-reason").textContent).toBe(
      "Please attach a revised budget breakdown."
    );
    expect(notice.querySelector("lightning-button")).not.toBeNull();
  });

  it("disables the resubmit button while the call is in flight", async () => {
    getMyRequests.mockResolvedValue([
      {
        requestId: "a01xx0000000005",
        requestNumber: "MDF-000005",
        campaignName: "Spring Expo",
        requestType: "Event",
        requestedAmount: 1500,
        approvedAmount: null,
        status: "Needs Information",
        returnReason: "Missing sponsor letter."
      }
    ]);
    let resolveResubmit;
    resubmitRequest.mockReturnValue(
      new Promise((resolve) => {
        resolveResubmit = resolve;
      })
    );

    const element = createElement("c-ps-mdf-list", { is: PsMdfList });
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    const button = element.shadowRoot.querySelector(
      ".return-notice lightning-button"
    );
    expect(button.disabled).toBe(false);

    button.click();
    await flushPromises();

    expect(button.disabled).toBe(true);

    resolveResubmit();
    await flushPromises();
    await flushPromises();
  });

  it("resubmits a request and reloads the list on success", async () => {
    getMyRequests.mockResolvedValueOnce([
      {
        requestId: "a01xx0000000003",
        requestNumber: "MDF-000003",
        campaignName: "Winter Summit",
        requestType: "Event",
        requestedAmount: 4000,
        approvedAmount: null,
        status: "Needs Information",
        returnReason: "Missing sponsor letter."
      }
    ]);
    resubmitRequest.mockResolvedValue();
    getMyRequests.mockResolvedValueOnce([
      {
        requestId: "a01xx0000000003",
        requestNumber: "MDF-000003",
        campaignName: "Winter Summit",
        requestType: "Event",
        requestedAmount: 4000,
        approvedAmount: null,
        status: "Submitted",
        returnReason: null
      }
    ]);

    const element = createElement("c-ps-mdf-list", { is: PsMdfList });
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    const button = element.shadowRoot.querySelector(
      ".return-notice lightning-button"
    );
    button.click();

    await flushPromises();
    await flushPromises();
    await flushPromises();
    await flushPromises();

    expect(resubmitRequest).toHaveBeenCalledWith({
      requestId: "a01xx0000000003"
    });
    expect(getMyRequests).toHaveBeenCalledTimes(2);
    expect(element.shadowRoot.querySelector(".return-notice")).toBeNull();
  });

  it("shows an error when resubmitting fails", async () => {
    getMyRequests.mockResolvedValue([
      {
        requestId: "a01xx0000000004",
        requestNumber: "MDF-000004",
        campaignName: "Q1 Campaign",
        requestType: "Event",
        requestedAmount: 2000,
        approvedAmount: null,
        status: "Needs Information",
        returnReason: "Missing sponsor letter."
      }
    ]);
    resubmitRequest.mockRejectedValue({
      body: { message: "Unable to resubmit MDF request." }
    });

    const element = createElement("c-ps-mdf-list", { is: PsMdfList });
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    const button = element.shadowRoot.querySelector(
      ".return-notice lightning-button"
    );
    button.click();

    await flushPromises();
    await flushPromises();

    const errorPanels = element.shadowRoot.querySelectorAll("c-ps-error-panel");
    expect(errorPanels).toHaveLength(1);
    expect(errorPanels[0].message).toBe("Unable to resubmit MDF request.");
  });
});
