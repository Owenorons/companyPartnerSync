import { createElement } from "@lwc/engine-dom";
import PsNotificationBell from "c/psNotificationBell";
import getUnreadCount from "@salesforce/apex/NotificationController.getUnreadCount";

jest.mock(
  "@salesforce/apex/NotificationController.getUnreadCount",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

const flushPromises = () =>
  // A timer is intentional in this test helper: initialization chains several
  // promises and an LWC render, which a fixed number of microtasks cannot
  // reliably drain when Jest runs suites in parallel.
  // eslint-disable-next-line @lwc/lwc/no-async-operation
  new Promise((resolve) => setTimeout(resolve, 0));

describe("c-ps-notification-bell", () => {
  beforeEach(() => {
    getUnreadCount.mockResolvedValue(3);
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    jest.useRealTimers();
  });

  it("loads the unread count and opens the drawer", async () => {
    const element = createElement("c-ps-notification-bell", {
      is: PsNotificationBell
    });
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    expect(element.shadowRoot.querySelector(".badge").textContent).toBe("3");

    element.shadowRoot.querySelector("button").click();
    await flushPromises();
    expect(element.shadowRoot.querySelector("c-ps-drawer")).not.toBeNull();
  });

  it("polls for unread-count changes", async () => {
    jest.useFakeTimers();
    const element = createElement("c-ps-notification-bell", {
      is: PsNotificationBell
    });
    document.body.appendChild(element);
    await Promise.resolve();
    await Promise.resolve();
    getUnreadCount.mockClear();

    getUnreadCount.mockResolvedValue(4);
    jest.advanceTimersByTime(60000);
    await Promise.resolve();
    await Promise.resolve();

    expect(getUnreadCount).toHaveBeenCalledTimes(1);
    expect(element.shadowRoot.querySelector(".badge").textContent).toBe("4");
  });

  it("stops polling when removed from the page", async () => {
    const clearIntervalSpy = jest.spyOn(global, "clearInterval");
    const element = createElement("c-ps-notification-bell", {
      is: PsNotificationBell
    });
    document.body.appendChild(element);
    await flushPromises();
    await flushPromises();

    document.body.removeChild(element);
    expect(clearIntervalSpy).toHaveBeenCalled();
    clearIntervalSpy.mockRestore();
  });
});
