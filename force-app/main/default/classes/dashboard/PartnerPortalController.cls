/*
 * Aura/LWC entry point for the partner portal dashboard. Thin boundary
 * that delegates to PartnerDashboardService and translates exceptions
 * into AuraHandledException, matching InternalPortalController's pattern
 * for the internal-facing side.
 */
public with sharing class PartnerPortalController {
  @AuraEnabled(cacheable=true)
  public static PartnerDashboardDTO getDashboard() {
    try {
      return PartnerDashboardService.getDashboard();
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'PartnerPortalController',
        'Unable to load partner dashboard.',
        ex
      );

      throw new AuraHandledException('Unable to load dashboard.');
    }
  }
}
