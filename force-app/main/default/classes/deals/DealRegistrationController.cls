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
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealRegistrationController',
        'Unable to create deal registration.',
        'Unable to create deal registration.',
        ex
      );
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<EligibleOpportunityDTO> getEligibleOpportunities() {
    try {
      return DealRegistrationService.getEligibleOpportunities();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealRegistrationController',
        'Unable to load eligible opportunities.',
        'Unable to load eligible opportunities.',
        ex
      );
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<DealRegistrationListDTO> getMyDeals() {
    try {
      return DealRegistrationService.getMyDeals();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealRegistrationController',
        'Unable to load partner deals.',
        'Unable to load deals.',
        ex
      );
    }
  }
}
