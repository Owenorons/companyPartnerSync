import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getReviewQueue from "@salesforce/apex/PartnerDocumentReviewController.getReviewQueue";
import reviewDocument from "@salesforce/apex/PartnerDocumentReviewController.reviewDocument";

const STATUS_OPTIONS = [
  { label: "All Statuses", value: "" },
  { label: "Submitted", value: "Submitted" },
  { label: "Under Review", value: "Under Review" },
  { label: "Accepted", value: "Accepted" },
  { label: "Rejected", value: "Rejected" },
  { label: "Replacement Required", value: "Replacement Required" }
];

const OUTCOME_OPTIONS = [
  { label: "Accepted", value: "Accepted" },
  { label: "Rejected", value: "Rejected" },
  { label: "Replacement Required", value: "Replacement Required" }
];

export default class PsDocumentReviewWorkspace extends LightningElement {
  documents = [];
  selectedDocument;
  selectedDocumentId;
  selectedStatus = "";
  searchTerm = "";
  error;
  submitting = false;
  submitError;
  outcome = "Accepted";
  reason = "";
  wiredQueueResult;

  statusOptions = STATUS_OPTIONS;
  outcomeOptions = OUTCOME_OPTIONS;

  @wire(getReviewQueue)
  wiredReviewQueue(result) {
    this.wiredQueueResult = result;

    if (result.data) {
      this.documents = result.data.map((doc) => this.toQueueViewModel(doc));
      this.error = undefined;

      const stillSelected = this.documents.find(
        (doc) => doc.documentId === this.selectedDocumentId
      );

      if (stillSelected) {
        this.selectedDocument = stillSelected;
      } else if (this.documents.length > 0) {
        this.selectDocument(this.documents[0]);
      } else {
        this.selectedDocument = undefined;
        this.selectedDocumentId = undefined;
      }
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load document review queue."
      );
      this.documents = [];
      this.selectedDocument = undefined;
      this.selectedDocumentId = undefined;
    }
  }

  get filteredDocuments() {
    const term = this.searchTerm.trim().toLowerCase();

    return this.documents
      .filter((doc) => {
        const matchesSearch =
          !term ||
          doc.partnerName?.toLowerCase().includes(term) ||
          doc.documentType?.toLowerCase().includes(term);

        const matchesStatus =
          !this.selectedStatus || doc.status === this.selectedStatus;

        return matchesSearch && matchesStatus;
      })
      .map((doc) => ({
        ...doc,
        rowClass:
          doc.documentId === this.selectedDocumentId
            ? "queue-row active"
            : "queue-row"
      }));
  }

  get hasFilteredDocuments() {
    return this.filteredDocuments.length > 0;
  }

  get showEmptyQueue() {
    return !this.error && !this.hasFilteredDocuments;
  }

  get isDecidable() {
    return (
      this.selectedDocument?.status === "Submitted" ||
      this.selectedDocument?.status === "Under Review"
    );
  }

  get isSubmitDisabled() {
    if (this.submitting || !this.outcome) {
      return true;
    }

    return this.outcome !== "Accepted" && !this.reason.trim();
  }

  handleSearch(event) {
    this.searchTerm = event.target.value || "";
  }

  handleStatus(event) {
    this.selectedStatus = event.detail.value;
  }

  handleSelectDocument(event) {
    const doc = this.documents.find(
      (candidate) => candidate.documentId === event.currentTarget.dataset.id
    );
    this.selectDocument(doc);
  }

  handleOutcomeChange(event) {
    this.outcome = event.detail.value;
  }

  handleReasonChange(event) {
    this.reason = event.target.value || "";
  }

  async handleSubmit() {
    if (this.isSubmitDisabled || !this.selectedDocumentId) {
      return;
    }

    this.submitting = true;
    this.submitError = undefined;

    try {
      await reviewDocument({
        request: {
          documentId: this.selectedDocumentId,
          outcome: this.outcome,
          reason: this.reason.trim()
        }
      });

      this.reason = "";
      this.outcome = "Accepted";
      await refreshApex(this.wiredQueueResult);
    } catch (error) {
      this.submitError = this.getErrorMessage(
        error,
        "Unable to process document review decision."
      );
    } finally {
      this.submitting = false;
    }
  }

  selectDocument(doc) {
    this.selectedDocument = doc;
    this.selectedDocumentId = doc?.documentId;
    this.outcome = "Accepted";
    this.reason = "";
    this.submitError = undefined;
  }

  toQueueViewModel(doc) {
    return {
      ...doc,
      partnerName: doc.partnerName || "Unknown partner",
      statusClass: this.getStatusClass(doc.status),
      submittedOnLabel: this.formatDateTime(doc.submittedOn),
      downloadUrl: doc.contentDocumentId
        ? `/sfc/servlet.shepherd/document/download/${doc.contentDocumentId}`
        : null
    };
  }

  formatDateTime(value) {
    if (!value) {
      return "Not submitted";
    }

    return new Intl.DateTimeFormat("en-AU", {
      dateStyle: "medium",
      timeStyle: "short"
    }).format(new Date(value));
  }

  getStatusClass(status) {
    if (status === "Accepted") {
      return "ps-badge ps-badge-success";
    }

    if (status === "Rejected" || status === "Replacement Required") {
      return "ps-badge ps-badge-danger";
    }

    return "ps-badge ps-badge-warning";
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
