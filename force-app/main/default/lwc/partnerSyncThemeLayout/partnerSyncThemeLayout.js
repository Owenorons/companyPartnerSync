import { LightningElement } from "lwc";
import { loadStyle } from "lightning/platformResourceLoader";
import PARTNER_SYNC_THEME_TOKENS from "@salesforce/resourceUrl/PartnerSync_Theme_Tokens";

/**
 * @slot header This is the header slot.
 * @slot footer This is the footer slot
 * @slot default This is the default slot
 */
export default class PartnerSyncThemeLayout extends LightningElement {
  connectedCallback() {
    loadStyle(this, PARTNER_SYNC_THEME_TOKENS).catch((error) => {
      console.error("Unable to load PartnerSync theme tokens.", error);
    });
  }
}
