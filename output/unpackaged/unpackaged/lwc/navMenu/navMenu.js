import { LightningElement, api, wire } from "lwc";
import { CurrentPageReference, NavigationMixin } from "lightning/navigation";
import getNavigationMenuItems from "@salesforce/apex/NavMenuItemsController.getNavigationMenuItems";
import isGuestUser from "@salesforce/user/isGuest";
import basePath from "@salesforce/community/basePath";

const BUILDER_PREVIEW_APP = "commeditor";

/**
 * This is a custom LWC navigation menu component, modeled on
 * trailheadapps/az-insurance's navigationMenu/navigationMenuItem pair.
 * Individual item rendering (href generation + click navigation) is
 * delegated to c-nav-menu-items — see that component for the
 * SalesforceObject/InternalLink/ExternalLink PageReference resolution.
 *
 * Make sure the Guest user profile has access to the
 * NavMenuItemsController Apex class if this menu appears on public pages.
 */
export default class NavMenu extends NavigationMixin(LightningElement) {
  @api buttonLabel;
  @api buttonRedirectPageAPIName;
  @api menuName;

  error;
  href = basePath;
  isLoaded = false;
  menuItems = [];
  publishedState = "Live";
  showHamburgerMenu = false;
  expandedItemId = null;

  @wire(CurrentPageReference)
  setCurrentPageReference(currentPageReference) {
    const app = currentPageReference?.state?.app;
    this.publishedState = app === BUILDER_PREVIEW_APP ? "Draft" : "Live";
  }

  @wire(getNavigationMenuItems, {
    menuName: "$menuName",
    publishedState: "$publishedState"
  })
  wiredMenuItems({ data, error }) {
    this.isLoaded = true;

    if (data) {
      const visibleItems = data
        .map((item) => ({
          id: item.Id,
          parentId: item.ParentId,
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

      this.menuItems = this.buildMenuTree(visibleItems);
      this.error = undefined;
    } else if (error) {
      this.error =
        error?.body?.message || "Unable to load the navigation menu.";
      this.menuItems = [];
    }
  }

  get hasMenuItems() {
    return this.menuItems.length > 0;
  }

  get displayMenuItems() {
    return this.menuItems.map((item) => ({
      ...item,
      itemClass:
        item.hasChildren && this.expandedItemId === item.id
          ? "nav-item is-expanded"
          : "nav-item"
    }));
  }

  get hasButton() {
    return Boolean(this.buttonLabel && this.buttonRedirectPageAPIName);
  }

  get navClass() {
    return this.showHamburgerMenu ? "nav-list is-open" : "nav-list";
  }

  get toggleLabel() {
    return this.showHamburgerMenu ? "Close menu" : "Open menu";
  }

  buildMenuTree(items) {
    const childrenByParentId = new Map();
    const topLevelItems = [];

    for (const item of items) {
      if (!item.parentId) {
        topLevelItems.push(item);
        continue;
      }

      const siblings = childrenByParentId.get(item.parentId) || [];
      siblings.push(item);
      childrenByParentId.set(item.parentId, siblings);
    }

    return topLevelItems.map((item) =>
      this.toMenuItemViewModel(item, childrenByParentId)
    );
  }

  toMenuItemViewModel(item, childrenByParentId) {
    const children = (childrenByParentId.get(item.id) || []).map((child) =>
      this.toMenuItemViewModel(child, childrenByParentId)
    );

    return {
      ...item,
      hasChildren: children.length > 0,
      children
    };
  }

  handleItemNavigation() {
    this.showHamburgerMenu = false;
    this.expandedItemId = null;
  }

  handleSubmenuToggle(event) {
    event.stopPropagation();
    event.preventDefault();

    const itemId = event.currentTarget.dataset.id;
    this.expandedItemId = this.expandedItemId === itemId ? null : itemId;
  }

  handleClick() {
    this[NavigationMixin.Navigate]({
      type: "comm__namedPage",
      attributes: {
        name: this.buttonRedirectPageAPIName
      }
    });
  }

  handleHamburgerMenuToggle(evt) {
    evt.stopPropagation();
    evt.preventDefault();

    this.showHamburgerMenu = !this.showHamburgerMenu;
    this.expandedItemId = null;
  }
}
