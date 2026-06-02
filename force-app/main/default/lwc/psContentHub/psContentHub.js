import { LightningElement, wire } from "lwc";
import getAvailableContent from "@salesforce/apex/PartnerContentController.getAvailableContent";
import getCategories from "@salesforce/apex/PartnerContentController.getCategories";
import getDownloadUrl from "@salesforce/apex/PartnerContentController.getDownloadUrl";

export default class PsContentHub extends LightningElement {
  content = [];
  categories = [];
  searchTerm = "";
  selectedCategory = "";

  @wire(getAvailableContent)
  wiredContent({ data }) {
    if (data) {
      this.content = data;
    }
  }

  @wire(getCategories)
  wiredCategories({ data }) {
    if (data) {
      this.categories = data;
    }
  }

  get categoryOptions() {
    return [
      { label: "All Categories", value: "" },
      ...this.categories.map((item) => ({
        label: item.label,
        value: item.value
      }))
    ];
  }

  get featuredContent() {
    return this.filteredContent.filter((item) => item.featured);
  }

  get filteredContent() {
    const term = this.searchTerm.toLowerCase();

    return this.content.filter((item) => {
      const matchesSearch =
        !term ||
        item.title?.toLowerCase().includes(term) ||
        item.description?.toLowerCase().includes(term);

      const matchesCategory =
        !this.selectedCategory || item.category === this.selectedCategory;

      return matchesSearch && matchesCategory;
    });
  }

  handleSearch(event) {
    this.searchTerm = event.target.value;
  }

  handleCategory(event) {
    this.selectedCategory = event.detail.value;
  }

  async handleDownload(event) {
    const contentId = event.detail.contentId;

    const result = await getDownloadUrl({ contentId });

    if (result?.downloadUrl) {
      window.open(result.downloadUrl, "_blank");
    }
  }
}
