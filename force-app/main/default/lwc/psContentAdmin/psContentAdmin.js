import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getAllContent from "@salesforce/apex/PartnerContentController.getAllContent";
import saveContent from "@salesforce/apex/PartnerContentController.saveContent";

const CATEGORY_OPTIONS = [
  { label: "Sales Deck", value: "Sales Deck" },
  { label: "Product Sheet", value: "Product Sheet" },
  { label: "Pricing Guide", value: "Pricing Guide" },
  { label: "Marketing Asset", value: "Marketing Asset" },
  { label: "Training", value: "Training" },
  { label: "Case Study", value: "Case Study" }
];

const VISIBILITY_OPTIONS = [
  { label: "All Partners", value: "All Partners" },
  { label: "Internal Only", value: "Internal Only" },
  { label: "Restricted", value: "Restricted" }
];

const PARTNER_TIER_OPTIONS = [
  { label: "Silver", value: "Silver" },
  { label: "Gold", value: "Gold" },
  { label: "Platinum", value: "Platinum" },
  { label: "Strategic", value: "Strategic" }
];

const PARTNER_TYPE_OPTIONS = [
  { label: "Distributor", value: "Distributor" },
  { label: "Reseller", value: "Reseller" },
  { label: "Agent", value: "Agent" },
  { label: "Dealer", value: "Dealer" },
  { label: "Referral", value: "Referral" }
];

export default class PsContentAdmin extends LightningElement {
  acceptedFormats = [
    ".pdf",
    ".png",
    ".jpg",
    ".jpeg",
    ".docx",
    ".pptx",
    ".xlsx"
  ];

  content = [];
  error;
  loading = true;
  saving = false;
  isModalOpen = false;
  draft = {};
  uploadedFileName;

  categoryOptions = CATEGORY_OPTIONS;
  visibilityOptions = VISIBILITY_OPTIONS;
  partnerTierOptions = PARTNER_TIER_OPTIONS;
  partnerTypeOptions = PARTNER_TYPE_OPTIONS;

  wiredResult;

  @wire(getAllContent)
  wiredContent(result) {
    this.wiredResult = result;
    this.loading = false;

    if (result.data) {
      this.content = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load content."
      );
    }
  }

  get hasContent() {
    return this.content.length > 0;
  }

  get rows() {
    return this.content.map((item) => ({
      ...item,
      statusLabel: item.isActive ? "Active" : "Inactive",
      statusVariant: item.isActive ? "success" : "neutral"
    }));
  }

  get isNewContent() {
    return !this.draft.contentId;
  }

  get modalTitle() {
    return this.isNewContent ? "New Content" : "Edit Content";
  }

  get hasAttachedFile() {
    return Boolean(this.draft.contentDocumentId);
  }

  get attachedFileLabel() {
    if (this.uploadedFileName) {
      return `Uploaded: ${this.uploadedFileName}`;
    }

    return this.hasAttachedFile ? "A file is already attached." : "";
  }

  get isSaveDisabled() {
    return this.saving || (this.isNewContent && !this.draft.contentDocumentId);
  }

  handleAddNew() {
    this.draft = {};
    this.uploadedFileName = undefined;
    this.isModalOpen = true;
  }

  handleEdit(event) {
    const contentId = event.currentTarget.dataset.id;
    const item = this.content.find((row) => row.contentId === contentId);

    if (!item) {
      return;
    }

    this.draft = { ...item };
    this.uploadedFileName = undefined;
    this.isModalOpen = true;
  }

  handleUploadFinished(event) {
    const uploadedFiles = event.detail.files;

    if (!uploadedFiles || uploadedFiles.length === 0) {
      return;
    }

    this.draft = {
      ...this.draft,
      contentDocumentId: uploadedFiles[0].documentId
    };
    this.uploadedFileName = uploadedFiles[0].name;
  }

  handleInputChange(event) {
    this.draft = { ...this.draft, [event.target.name]: event.target.value };
  }

  handleComboboxChange(event) {
    this.draft = {
      ...this.draft,
      [event.target.name]: event.detail.value
    };
  }

  handleCheckboxChange(event) {
    this.draft = {
      ...this.draft,
      [event.target.name]: event.target.checked
    };
  }

  handleCloseModal() {
    this.isModalOpen = false;
    this.draft = {};
    this.uploadedFileName = undefined;
  }

  async handleSaveDraft() {
    await this.persist(this.draft);

    if (!this.error) {
      this.isModalOpen = false;
      this.draft = {};
      this.uploadedFileName = undefined;
    }
  }

  async handleToggleActive(event) {
    const contentId = event.currentTarget.dataset.id;
    const item = this.content.find((row) => row.contentId === contentId);

    if (!item) {
      return;
    }

    await this.persist({ ...item, isActive: !item.isActive });
  }

  async persist(dto) {
    this.saving = true;
    this.error = undefined;

    try {
      await saveContent({ content: dto });
      await refreshApex(this.wiredResult);
    } catch (error) {
      this.error = this.getErrorMessage(error, "Unable to save content.");
    } finally {
      this.saving = false;
    }
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
