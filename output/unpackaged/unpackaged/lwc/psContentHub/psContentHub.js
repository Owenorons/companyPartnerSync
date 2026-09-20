import { LightningElement, wire } from "lwc";
import getAvailableContent from "@salesforce/apex/PartnerContentController.getAvailableContent";
import getCategories from "@salesforce/apex/PartnerContentController.getCategories";
import getDownloadUrl from "@salesforce/apex/PartnerContentController.getDownloadUrl";

export default class PsContentHub extends LightningElement {
  content = [];
  categories = [];
  error;
  searchTerm = "";
  selectedCategory = "";

  @wire(getAvailableContent)
  wiredContent({ data, error }) {
    if (data) {
      this.content = Array.isArray(data) ? data : [];
      this.error = undefined;
    } else if (error) {
      this.error = this.getErrorMessage(error, "Unable to load content.");
      this.content = [];
    }
  }

  @wire(getCategories)
  wiredCategories({ data, error }) {
    if (data) {
      this.categories = Array.isArray(data) ? data : [];
    } else if (error) {
      this.categories = [];
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

  get hasFeaturedContent() {
    return this.featuredContent.length > 0;
  }

  get hasFilteredContent() {
    return this.filteredContent.length > 0;
  }

  get filteredContent() {
    const term = (this.searchTerm || "").trim().toLowerCase();

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
    this.searchTerm = event.target.value || "";
  }

  handleCategory(event) {
    this.selectedCategory = event.detail.value;
  }

  async handleDownload(event) {
    const contentId = event.detail.contentId;

    if (!contentId) {
      return;
    }

    try {
      const result = await getDownloadUrl({ contentId });

      if (result?.downloadUrl) {
        window.open(result.downloadUrl, "_blank");
      }
    } catch (error) {
      this.error = this.getErrorMessage(error, "Unable to open content.");
    }
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
