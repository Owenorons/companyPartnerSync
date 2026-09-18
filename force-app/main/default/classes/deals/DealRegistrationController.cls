/**
 * Aura-enabled entry point for the partner-facing "register a deal" LWC.
 * Thin wrapper only: delegates to DealRegistrationService and translates
 * handled exceptions into AuraHandledException. Compare to
 * DealReviewController, the equivalent entry point for the internal
 * review/approval workflow.
 */
public with sharing class DealRegistrationController {
  /**
   * Creates a new deal registration for the current partner.
   *
   * @param request Partner-submitted registration details.
   * @return A minimal confirmation DTO for the newly created deal registration.
   */
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

  /**
   * Lists the current partner's opportunities that are eligible for a new deal registration.
   *
   * @return Row shapes for the "register a deal" opportunity picker.
   */
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

  /**
   * Lists the current partner's own deal registrations for the "My Deals" list.
   *
   * @return Row shapes for the current partner's deal registrations.
   */
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
