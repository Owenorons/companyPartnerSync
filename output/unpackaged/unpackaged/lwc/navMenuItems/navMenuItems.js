import { LightningElement, api, track, wire } from "lwc";
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import basePath from "@salesforce/community/basePath";
export default class NavMenuItems extends NavigationMixin(LightningElement) {
  /**
   * The NavigationMenuItem from the Apex controller,
   * contains a label and a target.
   */
  @api item = {};

  /**
   * "default" for a top-level nav link, "submenu" for a dropdown item —
   * purely a styling hook (see navMenuItems.css), no behavior difference.
   */
  @api variant = "default";

  @track href = "#";
  @track isCurrent = false;

  /**
   * the PageReference object used by lightning/navigation
   */
  pageReference;

  @wire(CurrentPageReference)
  wiredCurrentPageReference() {
    this.updateCurrentState();
  }

  connectedCallback() {
    const { type, target, defaultListViewId } = this.item;

    // get the correct PageReference object for the menu item type
    if (type === "SalesforceObject") {
      // aka "Salesforce Object" menu item
      this.pageReference = {
        type: "standard__objectPage",
        attributes: {
          objectApiName: target
        },
        state: {
          filterName: defaultListViewId
        }
      };
    } else if (type === "InternalLink") {
      // aka "Site Page" menu item

      // WARNING: Normally you shouldn't use 'standard__webPage' for internal relative targets, but
      // we don't have a way of identifying the Page Reference type of an InternalLink URL
      this.pageReference = {
        type: "standard__webPage",
        attributes: {
          url: basePath + target
        }
      };
    } else if (type === "ExternalLink") {
      // aka "External URL" menu item
      this.pageReference = {
        type: "standard__webPage",
        attributes: {
          url: target
        }
      };
    }

    // use the NavigationMixin from lightning/navigation to generate the URL for navigation.
    if (this.pageReference) {
      this[NavigationMixin.GenerateUrl](this.pageReference)
        .then((url) => {
          this.href = url;
          this.updateCurrentState();
        })
        .catch((error) => {
          console.error("Unable to generate navigation URL", error);
        });
    }
  }

  get linkClass() {
    return this.isCurrent ? "nav-link is-current" : "nav-link";
  }

  get ariaCurrent() {
    return this.isCurrent ? "page" : null;
  }

  get hasChildren() {
    return Boolean(this.item?.hasChildren);
  }

  updateCurrentState() {
    if (!this.href || this.href === "#") {
      this.isCurrent = false;
      return;
    }

    try {
      const resolvedPath = new URL(
        this.href,
        window.location.origin
      ).pathname.replace(/\/+$/, "");
      const currentPath = window.location.pathname.replace(/\/+$/, "");
      this.isCurrent = resolvedPath !== "" && resolvedPath === currentPath;
    } catch {
      this.isCurrent = false;
    }
  }

  handleNavigation() {
    this.dispatchEvent(new CustomEvent("navigation"));
  }

  handleClick(evt) {
    // use the NavigationMixin from lightning/navigation to perform the navigation.
    evt.stopPropagation();
    evt.preventDefault();
    this.handleNavigation();
    if (this.pageReference) {
      this[NavigationMixin.Navigate](this.pageReference);
    } else {
      console.log(
        `Navigation menu type "${
          this.item.type
        }" not implemented for item ${JSON.stringify(this.item)}`
      );
    }
  }
}
