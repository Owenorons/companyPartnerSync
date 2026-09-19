/**
 * Aura-enabled controller for partner-facing analytics widgets (KPI tile,
 * leaderboard, customer revenue). Pure pass-through to AnalyticsService —
 * all permission/tenant-flag gating lives there, this layer only translates
 * handled vs. unexpected exceptions into AuraHandledException.
 */
public with sharing class AnalyticsController {
  /**
   * Retrieves the running user's own partner KPI summary.
   *
   * @return The current partner's KPI figures.
   */
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

  /**
   * Retrieves the cross-partner leaderboard of KPI figures. Requires
   * executive analytics access.
   *
   * @return One leaderboard row per active partner.
   */
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

  /**
   * Retrieves customer revenue grouped by customer and partner account,
   * across all partners. Requires executive analytics access.
   *
   * @return One row per distinct customer/partner account pairing with closed-won revenue.
   */
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
