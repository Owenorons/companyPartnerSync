/*
 * Aura-enabled entry points for the partner application flow (submit /
 * list pending / view detail). Thin adapter layer only — all logic lives in
 * PartnerApplicationService; this class just maps its exceptions to what
 * the LWC layer is allowed to see.
 */
public with sharing class PartnerApplicationController {
  @AuraEnabled
  public static PartnerApplicationResultDTO submitApplication(
    PartnerApplicationRequestDTO request
  ) {
    try {
      return PartnerApplicationService.submitApplication(request);
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'PartnerApplicationController',
        'Unable to submit application.',
        ex
      );

      throw new AuraHandledException(
        'Unable to submit application. Please contact support.'
      );
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<PartnerApplicationListDTO> getPendingApplications() {
    try {
      return PartnerApplicationService.getPendingApplications();
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'PartnerApplicationController',
        'Unable to load pending applications.',
        ex
      );

      throw new AuraHandledException('Unable to load pending applications.');
    }
  }

  @AuraEnabled(cacheable=true)
  public static PartnerApplicationDetailDTO getApplicationDetail(
    Id applicationId
  ) {
    try {
      return PartnerApplicationService.getApplicationDetail(applicationId);
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'PartnerApplicationController',
        'Unable to load application detail.',
        ex
      );

      throw new AuraHandledException('Unable to load application detail.');
    }
  }

  @AuraEnabled
  public static void claimApplication(Id applicationId) {
    try {
      PartnerApplicationService.claimApplication(applicationId);
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'PartnerApplicationController',
        'Unable to claim partner application.',
        ex
      );
      throw new AuraHandledException('Unable to claim partner application.');
    }
  }
}
