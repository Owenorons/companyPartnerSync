import { LightningElement, wire } from "lwc";
import getMyBudget from "@salesforce/apex/MDFController.getMyBudget";

export default class PsMdfWorkspace extends LightningElement {
  budget;
  refreshToken = Date.now();

  @wire(getMyBudget)
  wiredBudget({ data }) {
    if (data) {
      this.budget = data;
    }
  }

  handleRequestCreated() {
    this.refreshToken = Date.now();
  }
}
