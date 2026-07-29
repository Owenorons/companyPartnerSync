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
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'AnalyticsController',
        'Unable to load partner KPI.',
        ex
      );

      throw new AuraHandledException('Unable to load partner analytics.');
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<PartnerLeaderboardRowDTO> getPartnerLeaderboard() {
    try {
      return AnalyticsService.getPartnerLeaderboard();
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'AnalyticsController',
        'Unable to load partner leaderboard.',
        ex
      );

      throw new AuraHandledException('Unable to load partner leaderboard.');
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<CustomerRevenueDTO> getCustomerRevenue() {
    try {
      return AnalyticsService.getCustomerRevenue();
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'AnalyticsController',
        'Unable to load customer revenue analytics.',
        ex
      );

      throw new AuraHandledException(
        'Unable to load customer revenue analytics.'
      );
    }
  }
}
