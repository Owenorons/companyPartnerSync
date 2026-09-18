/**
 * Service layer for partner analytics. Orchestrates AnalyticsSelector +
 * AnalyticsDomain and is where permission gating is decided: getMyKPI is
 * self-service (a partner viewing their own account) so it only checks the
 * tenant feature flag, while the leaderboard and cross-partner revenue
 * views expose other partners' data and require the executive-analytics
 * permission.
 */
public with sharing class AnalyticsService {
  /**
   * Calculates the KPI summary for the running user's own partner account.
   * Requires analytics to be enabled for the tenant.
   *
   * @return The current partner's KPI figures.
   */
  public static PartnerKPIDTO getMyKPI() {
    if (!TenantConfigService.isAnalyticsEnabled()) {
      throw new PartnerSyncHandledException('Analytics is disabled.');
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    return calculatePartnerKPI(partnerAccountId);
  }

  /**
   * Calculates a KPI-based leaderboard row for every active partner
   * account. Requires executive analytics access, since this exposes other
   * partners' data.
   *
   * @return One leaderboard row per active partner.
   */
  public static List<PartnerLeaderboardRowDTO> getPartnerLeaderboard() {
    // Cross-partner view, so gate on the executive permission rather than
    // the self-service tenant flag used by getMyKPI.
    PartnerPermissionService.assertCanViewExecutiveAnalytics();

    List<PartnerLeaderboardRowDTO> results = new List<PartnerLeaderboardRowDTO>();

    List<Account> partners = AnalyticsSelector.selectActivePartners();
    Map<Id, AnalyticsDomain.KpiTotals> totals = AnalyticsSelector.selectKpiTotals(
      new Map<Id, Account>(partners).keySet()
    );
    for (Account partner : partners) {
      PartnerKPIDTO kpi = AnalyticsDomain.calculatePartnerKPI(
        totals.get(partner.Id),
        partner
      );

      results.add(AnalyticsDomain.buildLeaderboardRow(partner, kpi));
    }

    return results;
  }

  /**
   * Aggregates closed-won, partner-sourced opportunity revenue grouped by
   * customer account and partner account. Requires executive analytics
   * access, since this exposes other partners' data.
   *
   * @return One row per distinct customer/partner account pairing with its total revenue and opportunity count.
   */
  public static List<CustomerRevenueDTO> getCustomerRevenue() {
    PartnerPermissionService.assertCanViewExecutiveAnalytics();

    Map<String, CustomerRevenueDTO> grouped = new Map<String, CustomerRevenueDTO>();

    for (
      Opportunity opp : AnalyticsSelector.selectWonOpportunitiesForRevenue()
    ) {
      String key =
        String.valueOf(opp.AccountId) +
        ':' +
        String.valueOf(opp.Partner_Account__c);

      if (!grouped.containsKey(key)) {
        CustomerRevenueDTO dto = new CustomerRevenueDTO();

        dto.customerAccountId = opp.AccountId;
        dto.customerName = opp.Account == null ? null : opp.Account.Name;

        dto.partnerAccountId = opp.Partner_Account__c;
        dto.partnerName = opp.Partner_Account__r == null
          ? null
          : opp.Partner_Account__r.Name;

        dto.revenue = 0;
        dto.opportunityCount = 0;

        grouped.put(key, dto);
      }

      CustomerRevenueDTO current = grouped.get(key);

      current.revenue += opp.Amount == null ? 0 : opp.Amount;
      current.opportunityCount++;
    }

    return grouped.values();
  }

  private static PartnerKPIDTO calculatePartnerKPI(Id partnerAccountId) {
    return AnalyticsDomain.calculatePartnerKPI(
      AnalyticsSelector.selectKpiTotals(new Set<Id>{ partnerAccountId })
        .get(partnerAccountId),
      AnalyticsSelector.selectPartnerBudget(partnerAccountId)
    );
  }
}
