import { LightningElement, api } from "lwc";
import getMyNotifications from "@salesforce/apex/NotificationController.getMyNotifications";
import markAsRead from "@salesforce/apex/NotificationController.markAsRead";
import dismissNotification from "@salesforce/apex/NotificationController.dismiss";

const MINUTE = 60 * 1000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

function relativeTime(isoDate) {
  const elapsed = Date.now() - new Date(isoDate).getTime();

  if (elapsed < MINUTE) {
    return "Just now";
  }
  if (elapsed < HOUR) {
    return `${Math.floor(elapsed / MINUTE)}m ago`;
  }
  if (elapsed < DAY) {
    return `${Math.floor(elapsed / HOUR)}h ago`;
  }
  return `${Math.floor(elapsed / DAY)}d ago`;
}

export default class PsNotificationCenter extends LightningElement {
  _refreshToken;
  _connected = false;

  @api
  get refreshToken() {
    return this._refreshToken;
  }

  set refreshToken(value) {
    const changed = this._refreshToken !== value;
    this._refreshToken = value;

    if (changed && this._connected) {
      this.loadNotifications();
    }
  }

  notifications = [];
  error;
  loading = true;

  connectedCallback() {
    this._connected = true;
    this.loadNotifications();
  }

  async loadNotifications() {
    this.loading = true;

    try {
      this.notifications = await getMyNotifications();
      this.error = undefined;
    } catch (error) {
      this.error = error.body?.message || "Unable to load notifications.";
    } finally {
      this.loading = false;
    }
  }

  get hasNotifications() {
    return this.notes.length > 0;
  }

  get notes() {
    return (this.notifications || []).map((notification) => ({
      ...notification,
      relativeLabel: relativeTime(notification.createdDate),
      rowClass: notification.isRead ? "note-row" : "note-row unread",
      isHighPriority: notification.priority === "High"
    }));
  }

  async handleMarkAsRead(event) {
    const notificationId = event.currentTarget.dataset.id;

    try {
      await markAsRead(notificationId);
      this.notifications = this.notifications.map((notification) => {
        return notification.notificationId === notificationId
          ? { ...notification, isRead: true }
          : notification;
      });
    } catch (error) {
      this.error = error.body?.message || "Unable to update notification.";
    }
  }

  async handleDismiss(event) {
    event.stopPropagation();
    const notificationId = event.currentTarget.dataset.id;

    try {
      await dismissNotification(notificationId);
      this.notifications = this.notifications.filter(
        (notification) => notification.notificationId !== notificationId
      );
    } catch (error) {
      this.error = error.body?.message || "Unable to dismiss notification.";
    }
  }
}
