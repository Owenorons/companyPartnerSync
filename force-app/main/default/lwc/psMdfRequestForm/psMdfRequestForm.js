import { LightningElement } from "lwc";

const REQUEST_TYPE_OPTIONS = [
  { label: "Event", value: "Event" },
  { label: "Webinar", value: "Webinar" },
  { label: "Digital Advertising", value: "Digital Advertising" },
  { label: "Content Syndication", value: "Content Syndication" },
  { label: "Direct Mail", value: "Direct Mail" },
  { label: "Other", value: "Other" }
];

export default class PsMdfRequestForm extends LightningElement {
  requestType = "";
  campaignName = "";
  requestedAmount;
  campaignDescription = "";

  get requestTypeOptions() {
    return REQUEST_TYPE_OPTIONS;
  }

  handleChange(event) {
    this[event.target.name] = event.target.value;
  }

  handleRequestTypeChange(event) {
    this.requestType = event.detail.value;
  }

  handleSubmit(event) {
    event.preventDefault();

    this.dispatchEvent(
      new CustomEvent("requestcreated", {
        detail: {
          requestType: this.requestType,
          campaignName: this.campaignName,
          requestedAmount: Number(this.requestedAmount),
          campaignDescription: this.campaignDescription
        }
      })
    );
  }
}
