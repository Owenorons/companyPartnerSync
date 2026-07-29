import { LightningElement, wire } from "lwc";
import getMyBudget from "@salesforce/apex/MDFController.getMyBudget";
import submitRequest from "@salesforce/apex/MDFController.submitRequest";

export default class PsMdfWorkspace extends LightningElement {
  budget;
  error;
  refreshToken = Date.now();

  @wire(getMyBudget)
  wiredBudget({ data }) {
    if (data) {
      this.budget = data;
    }
  }

  async handleRequestCreated(event) {
    this.error = undefined;

    try {
      await submitRequest({ request: event.detail });
      this.refreshToken = Date.now();
    } catch (error) {
      this.error = error?.body?.message || "Unable to submit MDF request.";
    }
  }
}
