import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";

export default class PsLogo extends NavigationMixin(LightningElement) {
  @api logoUrl;
  @api wordmark = "PartnerSync";
  @api homePageName = "Home";

  get hasImage() {
    return Boolean(this.logoUrl);
  }

  get isClickable() {
    return Boolean(this.homePageName);
  }

  get linkClass() {
    return this.isClickable ? "logo-link" : "logo-link is-static";
  }

  handleClick(event) {
    event.preventDefault();

    if (!this.isClickable) {
      return;
    }

    this[NavigationMixin.Navigate]({
      type: "comm__namedPage",
      attributes: { name: this.homePageName }
    });
  }
}
