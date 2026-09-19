import { LightningElement, api } from "lwc";

const POSITIONS = new Set(["left", "right"]);

export default class PsDrawer extends LightningElement {
  @api title = "";
  @api position = "right";

  handleKeydown = (event) => {
    if (event.key === "Escape") {
      this.handleClose();
    }
  };

  connectedCallback() {
    document.addEventListener("keydown", this.handleKeydown);
  }

  disconnectedCallback() {
    document.removeEventListener("keydown", this.handleKeydown);
  }

  get panelClass() {
    const position = POSITIONS.has(this.position) ? this.position : "right";
    return `drawer-panel drawer-${position}`;
  }

  handleBackdropClick(event) {
    if (event.target === event.currentTarget) {
      this.handleClose();
    }
  }

  handleClose() {
    this.dispatchEvent(new CustomEvent("close"));
  }
}
