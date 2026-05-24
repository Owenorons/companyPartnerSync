import { api, LightningElement } from "lwc";

const NAV_ITEMS = [
  { name: "dashboard", label: "Dashboard", iconName: "utility:home" },
  { name: "leads", label: "Leads", iconName: "utility:lead" },
  { name: "deals", label: "Deals", iconName: "utility:opportunity" },
  { name: "mdf", label: "MDF", iconName: "utility:money" },
  { name: "contentHub", label: "Content Hub", iconName: "utility:file" },
  { name: "analytics", label: "Analytics", iconName: "utility:chart" }
];

export default class PsSideNav extends LightningElement {
  _activeItem = NAV_ITEMS[0].name;

  @api
  get activeItem() {
    return this._activeItem;
  }

  set activeItem(value) {
    this._activeItem = this.isKnownItem(value) ? value : NAV_ITEMS[0].name;
  }

  get navItems() {
    return NAV_ITEMS.map((item) => {
      const isActive = item.name === this._activeItem;

      return {
        ...item,
        ariaCurrent: isActive ? "page" : null,
        href: `#${item.name}`,
        mobileLabel: `Open ${item.label}`,
        className: [
          "slds-text-color_weak",
          "nav-item",
          "slds-media",
          "slds-media_center",
          isActive ? "active" : ""
        ]
          .filter(Boolean)
          .join(" ")
      };
    });
  }

  handleNavClick(event) {
    event.preventDefault();

    const selectedName = event.currentTarget.dataset.name;
    const selectedItem = NAV_ITEMS.find((item) => item.name === selectedName);

    if (!selectedItem || selectedName === this._activeItem) {
      return;
    }

    this._activeItem = selectedName;

    this.dispatchEvent(
      new CustomEvent("navigate", {
        detail: {
          name: selectedItem.name,
          label: selectedItem.label
        }
      })
    );
  }

  isKnownItem(value) {
    return NAV_ITEMS.some((item) => item.name === value);
  }
}
