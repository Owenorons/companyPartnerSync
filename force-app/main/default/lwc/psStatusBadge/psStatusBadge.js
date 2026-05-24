import { LightningElement, api } from "lwc";

export default class PsStatusBadge extends LightningElement {
  @api label;
  @api variant = "info";
  @api size = "md";

  get computedClass() {
    return `badge badge-${this.variant} badge-${this.size}`;
  }
}
