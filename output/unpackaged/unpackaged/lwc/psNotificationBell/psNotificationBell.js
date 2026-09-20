import { LightningElement } from "lwc";

import getUnreadCount from "@salesforce/apex/NotificationController.getUnreadCount";

export default class PsNotificationBell extends LightningElement {
  static POLLING_INTERVAL_MS = 60000;

  pollingInterval;
  unreadCount = 0;
  open = false;
  refreshToken = Date.now();

  connectedCallback() {
    this.refreshUnreadCount();

    // EMP API and platformShowToastEvent aren't supported by LWR Experience
    // Builder. Polling keeps the theme header loadable in both Builder and the
    // published site while still refreshing notification state.
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    this.pollingInterval = setInterval(
      () => this.refreshUnreadCount(),
      PsNotificationBell.POLLING_INTERVAL_MS
    );
  }

  disconnectedCallback() {
    if (this.pollingInterval) {
      clearInterval(this.pollingInterval);
      this.pollingInterval = null;
    }
  }

  get hasUnread() {
    return this.unreadCount > 0;
  }

  async refreshUnreadCount() {
    try {
      this.unreadCount = await getUnreadCount();
    } catch (error) {
      console.error("Unable to refresh unread notification count", error);
    }
  }

  togglePanel() {
    this.open = !this.open;

    if (this.open) {
      this.refreshToken = Date.now();
      this.refreshUnreadCount();
    }
  }

  closePanel() {
    this.open = false;
  }
}
