/*
 * Aura/LWC entry point for the internal portal dashboard. Thin boundary
 * that delegates to InternalDashboardService and translates exceptions
 * into AuraHandledException, matching PartnerPortalController's pattern
 * for the partner-facing side.
 */
public with sharing class InternalPortalController {
  @TestVisible
  private static Boolean testDashboardFailure = false;

  @AuraEnabled(cacheable=true)
  public static InternalDashboardDTO getDashboard() {
    try {
      if (Test.isRunningTest() && testDashboardFailure)
        throw new InternalPortalControllerException('Test dashboard failure.');
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

  @AuraEnabled
  public static void acknowledgeOperationalAlert(Id alertId) {
    try {
      PartnerAccessService.assertInternalUser();
      PartnerOperationalAlertService.acknowledge(alertId);
    } catch (Exception ex) {
      LoggingService.error(
        'InternalPortalController',
        'Unable to acknowledge operational alert.',
        ex
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  @AuraEnabled
  public static void transitionOperationalAlert(Id alertId, String actionName) {
    try {
      PartnerAccessService.assertInternalUser();
      if (actionName == 'resolve')
        PartnerOperationalAlertActionService.resolve(alertId);
      else if (actionName == 'reopen')
        PartnerOperationalAlertActionService.reopen(alertId);
      else
        throw new InternalPortalControllerException(
          'Unsupported operational alert action.'
        );
    } catch (Exception ex) {
      LoggingService.error(
        'InternalPortalController',
        'Unable to transition operational alert.',
        ex
      );
      throw new AuraHandledException(ex.getMessage());
    }
  }

  private class InternalPortalControllerException extends Exception {
  }
}
