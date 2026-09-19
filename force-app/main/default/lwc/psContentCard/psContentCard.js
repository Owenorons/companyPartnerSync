import { LightningElement, api } from "lwc";

export default class PsContentCard extends LightningElement {
  _content = {};

  @api
  get content() {
    return this._content;
  }

  set content(value) {
    this._content = value || {};
  }

  get category() {
    return this._content.category || "General";
  }

  get title() {
    return this._content.title || "Untitled content";
  }

  get description() {
    return this._content.description || "No description available.";
  }

  get isFeatured() {
    return Boolean(this._content.featured);
  }

  get isDownloadDisabled() {
    return !this._content.contentId;
  }

  handleDownload() {
    if (this.isDownloadDisabled) {
      return;
    }

    this.dispatchEvent(
      new CustomEvent("download", {
        detail: { contentId: this._content.contentId }
      })
    );
  }
}
