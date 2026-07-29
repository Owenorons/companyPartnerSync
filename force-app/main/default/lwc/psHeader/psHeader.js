import { api, LightningElement } from "lwc";

export default class PsHeader extends LightningElement {
  @api logoUrl;
  @api wordmark = "PartnerSync";
  @api homePageName = "Home";

  @api menuName;
  @api buttonLabel;
  @api buttonRedirectPageAPIName;
}
