/*
 * Aura/LWC entry point for the internal portal dashboard. Thin boundary
 * that delegates to InternalDashboardService and translates exceptions
 * into AuraHandledException, matching PartnerPortalController's pattern
 * for the partner-facing side.
 */
public with sharing class InternalPortalController {
  @AuraEnabled(cacheable=true)
  public static InternalDashboardDTO getDashboard() {
    try {
      return InternalDashboardService.getDashboard();
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'InternalPortalController',
        'Unable to load internal dashboard.',
        ex
      );

      throw new AuraHandledException('Unable to load dashboard.');
    }
  }
}
