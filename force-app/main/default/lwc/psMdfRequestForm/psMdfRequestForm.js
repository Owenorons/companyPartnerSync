import { LightningElement } from "lwc";

export default class PsMdfRequestForm extends LightningElement {
  campaignName = "";
  requestedAmount;
  businessJustification = "";

  handleChange(event) {
    this[event.target.name] = event.target.value;
  }

  handleSubmit(event) {
    event.preventDefault();

    this.dispatchEvent(
      new CustomEvent("requestcreated", {
        detail: {
          campaignName: this.campaignName,
          requestedAmount: Number(this.requestedAmount),
          businessJustification: this.businessJustification
        }
      })
    );
  }
}
