import { createElement } from "@lwc/engine-dom";
import PsNotificationCenter from "c/psNotificationCenter";
import getMyNotifications from "@salesforce/apex/NotificationController.getMyNotifications";
import markAsRead from "@salesforce/apex/NotificationController.markAsRead";
import dismissNotification from "@salesforce/apex/NotificationController.dismiss";

jest.mock(
  "@salesforce/apex/NotificationController.getMyNotifications",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/NotificationController.markAsRead",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/NotificationController.dismiss",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const flushPromises = () => Promise.resolve();

const NOTIFICATION = {
  notificationId: "a02xx0000000001",
  title: "MDF request approved",
  message: "Q3 Regional Webinar Series was approved.",
  priority: "Normal",
  isRead: false,
  createdDate: new Date().toISOString()
};

describe("c-ps-notification-center", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("renders notifications once loaded", async () => {
    getMyNotifications.mockResolvedValue([NOTIFICATION]);

    const element = createElement("c-ps-notification-center", {
      is: PsNotificationCenter
    });
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    const rows = element.shadowRoot.querySelectorAll(".note-item");
    expect(rows).toHaveLength(1);
    expect(element.shadowRoot.querySelector(".note-title").textContent).toBe(
      "MDF request approved"
    );
    expect(element.shadowRoot.querySelector("c-ps-empty-state")).toBeNull();
  });

  it("shows the empty state when there are no notifications", async () => {
    getMyNotifications.mockResolvedValue([]);

    const element = createElement("c-ps-notification-center", {
      is: PsNotificationCenter
    });
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector("c-ps-empty-state")).not.toBeNull();
  });

  it("shows an error panel when the Apex call fails", async () => {
    getMyNotifications.mockRejectedValue({
      body: { message: "Unable to load notifications." }
    });

    const element = createElement("c-ps-notification-center", {
      is: PsNotificationCenter
    });
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    const errorPanel = element.shadowRoot.querySelector("c-ps-error-panel");
    expect(errorPanel).not.toBeNull();
    expect(errorPanel.message).toBe("Unable to load notifications.");
  });

  it("marks a notification as read when clicked", async () => {
    getMyNotifications.mockResolvedValue([NOTIFICATION]);
    markAsRead.mockResolvedValue();

    const element = createElement("c-ps-notification-center", {
      is: PsNotificationCenter
    });
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    element.shadowRoot.querySelector(".note-row").click();
    await flushPromises();
    await flushPromises();

    expect(markAsRead).toHaveBeenCalledWith("a02xx0000000001");
    expect(
      element.shadowRoot.querySelector(".note-row").className
    ).not.toContain("unread");
  });

  it("removes a notification from the list when dismissed", async () => {
    getMyNotifications.mockResolvedValue([NOTIFICATION]);
    dismissNotification.mockResolvedValue();

    const element = createElement("c-ps-notification-center", {
      is: PsNotificationCenter
    });
    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    element.shadowRoot.querySelector(".note-dismiss").click();
    await flushPromises();
    await flushPromises();

    expect(dismissNotification).toHaveBeenCalledWith("a02xx0000000001");
    expect(element.shadowRoot.querySelectorAll(".note-item")).toHaveLength(0);
  });

  it("reloads when refreshToken changes", async () => {
    getMyNotifications.mockResolvedValue([]);

    const element = createElement("c-ps-notification-center", {
      is: PsNotificationCenter
    });
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    expect(getMyNotifications).toHaveBeenCalledTimes(1);

    element.refreshToken = Date.now();
    await flushPromises();
    await flushPromises();

    expect(getMyNotifications).toHaveBeenCalledTimes(2);
  });
});
