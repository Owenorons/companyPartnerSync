import { LightningElement, api } from "lwc";

export default class PsContentCard extends LightningElement {
  @api content;

  handleDownload() {
    this.dispatchEvent(
      new CustomEvent("download", {
        detail: { contentId: this.content.contentId }
      })
    );
  }
}
