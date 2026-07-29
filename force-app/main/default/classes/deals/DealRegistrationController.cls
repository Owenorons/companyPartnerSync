/*
 * Aura-enabled entry point for the partner-facing "register a deal" LWC.
 * Thin wrapper only: delegates to DealRegistrationService and translates
 * handled exceptions into AuraHandledException. Compare to
 * DealReviewController, the equivalent entry point for the internal
 * review/approval workflow.
 */
public with sharing class DealRegistrationController {
  @AuraEnabled
  public static DealRegistrationResultDTO createDealRegistration(
    DealRegistrationRequestDTO request
  ) {
    try {
      return DealRegistrationService.createDealRegistration(request);
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'DealRegistrationController',
        'Unable to create deal registration.',
        ex
      );

      throw new AuraHandledException('Unable to create deal registration.');
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<EligibleOpportunityDTO> getEligibleOpportunities() {
    try {
      return DealRegistrationService.getEligibleOpportunities();
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'DealRegistrationController',
        'Unable to load eligible opportunities.',
        ex
      );

      throw new AuraHandledException('Unable to load eligible opportunities.');
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<DealRegistrationListDTO> getMyDeals() {
    try {
      return DealRegistrationService.getMyDeals();
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'DealRegistrationController',
        'Unable to load partner deals.',
        ex
      );

      throw new AuraHandledException('Unable to load deals.');
    }
  }
}
