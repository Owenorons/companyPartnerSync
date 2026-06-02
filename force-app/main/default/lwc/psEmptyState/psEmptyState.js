import { api, LightningElement } from "lwc";

export default class PsEmptyState extends LightningElement {
  @api iconName = "utility:success";
  @api title = "No items";
  @api message = "";
  @api buttonLabel;

  handleClick() {
    this.dispatchEvent(new CustomEvent("action"));
  }
}
