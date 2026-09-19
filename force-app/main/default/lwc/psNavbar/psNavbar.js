import { LightningElement, api } from "lwc";

export default class PsNavbar extends LightningElement {
  @api logoUrl;
  @api wordmark = "PartnerSync";
  @api homePageName = "Home";
  @api menuName;
}
