import { LightningElement, api } from "lwc";

export default class PsFooter extends LightningElement {
  @api companyName = "PartnerSync";
  @api footerMenuName;

  get copyrightLabel() {
    const year = new Date().getFullYear();
    return `© ${year} ${this.companyName}. All rights reserved.`;
  }

  get hasFooterMenu() {
    return Boolean(this.footerMenuName);
  }
}
