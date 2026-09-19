import { api, LightningElement } from "lwc";

export default class PsErrorPanel extends LightningElement {
  @api message = "The requested data could not be loaded.";
}
