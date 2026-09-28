import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getOperationsHealth from "@salesforce/apex/PartnerSyncOperationsConsoleController.getOperationsHealth";
import retryDeadLetter from "@salesforce/apex/PartnerSyncOperationsConsoleController.retryDeadLetter";
import acknowledgeDeadLetter from "@salesforce/apex/PartnerSyncOperationsConsoleController.acknowledgeDeadLetter";

export default class PsOperationsConsole extends LightningElement {
  health;
  error;
  loading = true;
  busyDlqId;
  wiredHealthResult;

  @wire(getOperationsHealth)
  wiredHealth(result) {
    this.wiredHealthResult = result;
    this.loading = false;
    if (result.data) {
      this.health = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load the operations health summary."
      );
      this.health = undefined;
    }
  }

  get hasHealth() {
    return !!this.health;
  }

  get deadLetterRows() {
    return (this.health?.deadLetters || []).map((row) => ({
      ...row,
      isBusy: this.busyDlqId === row.dlqId
    }));
  }

  get hasDeadLetters() {
    return this.deadLetterRows.length > 0;
  }

  async handleRetry(event) {
    const dlqId = event.currentTarget.dataset.id;
    this.busyDlqId = dlqId;
    try {
      await retryDeadLetter({ dlqId });
      await refreshApex(this.wiredHealthResult);
      this.error = undefined;
    } catch (error) {
      this.error = this.getErrorMessage(error, "Unable to retry the event.");
    } finally {
      this.busyDlqId = undefined;
    }
  }

  async handleAcknowledge(event) {
    const dlqId = event.currentTarget.dataset.id;
    this.busyDlqId = dlqId;
    try {
      await acknowledgeDeadLetter({ dlqId });
      await refreshApex(this.wiredHealthResult);
      this.error = undefined;
    } catch (error) {
      this.error = this.getErrorMessage(
        error,
        "Unable to acknowledge the event."
      );
    } finally {
      this.busyDlqId = undefined;
    }
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
