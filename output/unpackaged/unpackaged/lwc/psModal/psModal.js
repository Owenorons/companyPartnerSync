import { LightningElement, api } from "lwc";

const SIZES = new Set(["small", "medium", "large"]);

export default class PsModal extends LightningElement {
  @api title = "";
  @api size = "medium";

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
    const size = SIZES.has(this.size) ? this.size : "medium";
    return `modal-panel modal-${size}`;
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
