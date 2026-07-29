import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import getProviders from "@salesforce/apex/AIInsightController.getProviders";
import testProviderConnection from "@salesforce/apex/AIInsightController.testProviderConnection";

export default class PsAiProviderAdmin extends LightningElement {
  providers = [];
  error;
  loading = true;
  testingProvider;

  wiredResult;

  @wire(getProviders)
  wiredProviders(result) {
    this.wiredResult = result;
    this.loading = false;

    if (result.data) {
      this.providers = result.data;
      this.error = undefined;
    } else if (result.error) {
      this.error = this.getErrorMessage(
        result.error,
        "Unable to load AI providers."
      );
    }
  }

  get hasProviders() {
    return this.providers.length > 0;
  }

  get rows() {
    return this.providers.map((provider) => ({
      ...provider,
      activeLabel: provider.active ? "Active" : "Inactive",
      activeVariant: provider.active ? "success" : "neutral",
      statusVariant: this.statusVariantFor(provider.connectionStatus),
      isTesting: this.testingProvider === provider.developerName
    }));
  }

  statusVariantFor(status) {
    if (status === "Connected") {
      return "success";
    }

    if (status === "Failed") {
      return "danger";
    }

    return "neutral";
  }

  async handleTestConnection(event) {
    const developerName = event.currentTarget.dataset.name;

    if (!developerName || this.testingProvider) {
      return;
    }

    this.testingProvider = developerName;
    this.error = undefined;

    try {
      await testProviderConnection({
        providerDeveloperName: developerName
      });
    } catch (error) {
      this.error = this.getErrorMessage(
        error,
        "Unable to test AI provider connection."
      );
    } finally {
      this.testingProvider = undefined;
      await refreshApex(this.wiredResult);
    }
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
