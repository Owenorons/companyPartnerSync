public with sharing class AnalyticsService {
  public static PartnerKPIDTO getMyKPI() {
    if (!TenantConfigService.isAnalyticsEnabled()) {
      throw new PartnerSyncHandledException('Analytics is disabled.');
    }

    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();

    return calculatePartnerKPI(partnerAccountId);
  }

  public static List<PartnerLeaderboardRowDTO> getPartnerLeaderboard() {
    PartnerPermissionService.assertCanAccessInternalAnalytics();

    List<PartnerLeaderboardRowDTO> results = new List<PartnerLeaderboardRowDTO>();

    for (Account partner : AnalyticsSelector.selectActivePartners()) {
      PartnerKPIDTO kpi = calculatePartnerKPI(partner.Id);

      results.add(AnalyticsDomain.buildLeaderboardRow(partner, kpi));
    }

    return results;
  }

  public static List<CustomerRevenueDTO> getCustomerRevenue() {
    PartnerPermissionService.assertCanAccessInternalAnalytics();

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
      AnalyticsSelector.selectPartnerLeads(partnerAccountId),
      AnalyticsSelector.selectPartnerDeals(partnerAccountId),
      AnalyticsSelector.selectPartnerOpportunities(partnerAccountId),
      AnalyticsSelector.selectPartnerBudget(partnerAccountId)
    );
  }
}
