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
  public static List<PartnerApplicationResultDTO> getPendingApplications() {
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
}
