/*
 * Aura-enabled controller for partner-facing analytics widgets (KPI tile,
 * leaderboard, customer revenue). Pure pass-through to AnalyticsService —
 * all permission/tenant-flag gating lives there, this layer only translates
 * handled vs. unexpected exceptions into AuraHandledException.
 */
public with sharing class AnalyticsController {
  @AuraEnabled(cacheable=true)
  public static PartnerKPIDTO getMyKPI() {
    try {
      return AnalyticsService.getMyKPI();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'AnalyticsController',
        'Unable to load partner KPI.',
        'Unable to load partner analytics.',
        ex
      );
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<PartnerLeaderboardRowDTO> getPartnerLeaderboard() {
    try {
      return AnalyticsService.getPartnerLeaderboard();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'AnalyticsController',
        'Unable to load partner leaderboard.',
        'Unable to load partner leaderboard.',
        ex
      );
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<CustomerRevenueDTO> getCustomerRevenue() {
    try {
      return AnalyticsService.getCustomerRevenue();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'AnalyticsController',
        'Unable to load customer revenue analytics.',
        'Unable to load customer revenue analytics.',
        ex
      );
    }
  }
}
