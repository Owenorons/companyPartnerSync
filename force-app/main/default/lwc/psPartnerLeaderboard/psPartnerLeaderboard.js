import { LightningElement, wire } from "lwc";
import getPartnerLeaderboard from "@salesforce/apex/AnalyticsController.getPartnerLeaderboard";

export default class PsPartnerLeaderboard extends LightningElement {
  partners = [];
  error;
  loading = true;

  @wire(getPartnerLeaderboard)
  wiredLeaderboard({ data, error }) {
    this.loading = false;

    if (data) {
      this.partners = (Array.isArray(data) ? data : [])
        .map((partner, index) => this.toViewModel(partner, index))
        .sort((left, right) => right.numericScore - left.numericScore)
        .map((partner, index) => ({
          ...partner,
          rank: index + 1
        }));
      this.error = undefined;
    } else if (error) {
      this.error = this.getErrorMessage(
        error,
        "Unable to load partner leaderboard."
      );
      this.partners = [];
    }
  }

  get hasPartners() {
    return this.partners.length > 0;
  }

  get totalRevenue() {
    return this.partners.reduce(
      (total, partner) => total + Number(partner.revenue || 0),
      0
    );
  }

  get totalRevenueLabel() {
    return this.formatCurrency(this.totalRevenue);
  }

  get wonDeals() {
    return this.partners.reduce(
      (total, partner) => total + Number(partner.wonDeals || 0),
      0
    );
  }

  get activePartners() {
    return this.partners.filter((partner) => partner.partnerStatus === "Active")
      .length;
  }

  toViewModel(partner, index) {
    const revenue = Number(partner.revenue || 0);
    const conversionRate = Number(partner.conversionRate || 0);
    const score = Number(partner.score || 0);

    const partnerTier = partner.partnerTier || "Unassigned";
    const tierModifier = partnerTier.toLowerCase();

    return {
      ...partner,
      partnerAccountId: partner.partnerAccountId || `partner-${index}`,
      partnerName: partner.partnerName || "Unnamed partner",
      partnerTier,
      wonDeals: partner.wonDeals || 0,
      revenue,
      numericScore: score,
      score: Math.round(score),
      revenueLabel: this.formatCurrency(revenue),
      conversionLabel: this.formatPercent(conversionRate),
      medallionClass: `medallion medallion-${tierModifier}`,
      tierChipClass: `tier-chip tier-${tierModifier}`
    };
  }

  formatCurrency(value) {
    return new Intl.NumberFormat("en-AU", {
      style: "currency",
      currency: "AUD",
      maximumFractionDigits: 0
    }).format(value || 0);
  }

  formatPercent(value) {
    return new Intl.NumberFormat("en-AU", {
      style: "percent",
      maximumFractionDigits: 0
    }).format(value || 0);
  }

  getErrorMessage(error, fallback) {
    return error?.body?.message || error?.message || fallback;
  }
}
