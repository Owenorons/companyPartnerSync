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
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerApplicationController',
        'Unable to submit application.',
        'Unable to submit application. Please contact support.',
        ex
      );
    }
  }

  @AuraEnabled(cacheable=true)
  public static List<PartnerApplicationListDTO> getPendingApplications() {
    try {
      return PartnerApplicationService.getPendingApplications();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerApplicationController',
        'Unable to load pending applications.',
        'Unable to load pending applications.',
        ex
      );
    }
  }

  @AuraEnabled(cacheable=true)
  public static PartnerApplicationDetailDTO getApplicationDetail(
    Id applicationId
  ) {
    try {
      return PartnerApplicationService.getApplicationDetail(applicationId);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerApplicationController',
        'Unable to load application detail.',
        'Unable to load application detail.',
        ex
      );
    }
  }

  @AuraEnabled
  public static void claimApplication(Id applicationId) {
    try {
      PartnerApplicationService.claimApplication(applicationId);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerApplicationController',
        'Unable to claim partner application.',
        'Unable to claim partner application.',
        ex
      );
    }
  }
}
