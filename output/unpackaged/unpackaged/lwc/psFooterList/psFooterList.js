import { LightningElement, api, wire } from "lwc";
import { CurrentPageReference } from "lightning/navigation";
import getNavigationMenuItems from "@salesforce/apex/NavMenuItemsController.getNavigationMenuItems";
import isGuestUser from "@salesforce/user/isGuest";

const BUILDER_PREVIEW_APP = "commeditor";

/**
 * Flat Navigation Menu renderer for the site footer — modeled on
 * trailheadapps/az-insurance's footerList/footerMenuItem pair, but reuses
 * c-nav-menu-items for href resolution/click navigation instead of a
 * dedicated footer item component, since footer links never have submenus
 * and c-nav-menu-items already handles that case (no caret, no dropdown).
 */
export default class PsFooterList extends LightningElement {
  @api menuName;

  menuItems = [];
  publishedState = "Live";

  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    const app = currentPageReference?.state?.app;
    this.publishedState = app === BUILDER_PREVIEW_APP ? "Draft" : "Live";
  }

  @wire(getNavigationMenuItems, {
    menuName: "$menuName",
    publishedState: "$publishedState"
  })
  wiredMenuItems({ data }) {
    if (!data) {
      this.menuItems = [];
      return;
    }

    this.menuItems = data
      .map((item) => ({
        id: item.Id,
        label: item.Label,
        type: item.Type,
        target: item.Target,
        defaultListViewId: item.DefaultListViewId,
        accessRestriction: item.AccessRestriction
      }))
      .filter(
        (item) =>
          item.accessRestriction === "None" ||
          (item.accessRestriction === "LoginRequired" && !isGuestUser)
      );
  }

  get hasMenuItems() {
    return this.menuItems.length > 0;
  }
}
