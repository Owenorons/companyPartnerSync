import { LightningElement, api } from "lwc";

export default class PsDashboardMetricCard extends LightningElement {
  @api label;
  @api value;
  @api iconName;
  @api iconAlternativeText;
  @api tone = "blue";

  get cardClass() {
    return `metric-card tone-${this.tone}`;
  }

  get computedIconAlternativeText() {
    return this.iconAlternativeText || this.label || "Metric";
  }
}
