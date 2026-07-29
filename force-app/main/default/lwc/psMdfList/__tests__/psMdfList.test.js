import { createElement } from "@lwc/engine-dom";
import PsMdfList from "c/psMdfList";
import getMyRequests from "@salesforce/apex/MDFController.getMyRequests";

jest.mock(
  "@salesforce/apex/MDFController.getMyRequests",
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
});
