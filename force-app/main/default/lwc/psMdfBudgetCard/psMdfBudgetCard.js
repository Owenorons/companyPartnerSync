import { LightningElement, api } from "lwc";

export default class PsMdfBudgetCard extends LightningElement {
  @api budget;

  get annual() {
    return this.budget?.annualBudget || 0;
  }

  get used() {
    return this.budget?.usedBudget || 0;
  }

  get remaining() {
    return this.budget?.remainingBudget || 0;
  }

  get annualLabel() {
    return this.formatCurrency(this.annual);
  }

  get usedLabel() {
    return this.formatCurrency(this.used);
  }

  get remainingLabel() {
    return this.formatCurrency(this.remaining);
  }

  get usedPercent() {
    if (this.annual === 0) {
      return 0;
    }

    return Math.min((this.used / this.annual) * 100, 100);
  }

  get progressFillStyle() {
    return `width: ${this.usedPercent}%`;
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("en-AU", {
      style: "currency",
      currency: "AUD",
      maximumFractionDigits: 0
    }).format(value || 0);
  }
}
