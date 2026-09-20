/**
 * Aura-enabled entry points for the partner application flow (submit /
 * list pending / view detail). Thin adapter layer only — all logic lives in
 * PartnerApplicationService; this class just maps its exceptions to what
 * the LWC layer is allowed to see.
 */
public with sharing class PartnerApplicationController {
  /**
   * Submits a new partner application.
   *
   * @param request The application submission payload.
   * @return A PartnerApplicationResultDTO summarizing the created
   * application.
   */
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

  /**
   * Retrieves the list of partner applications awaiting review.
   *
   * @return List of PartnerApplicationListDTO rows for the review queue.
   */
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

  /**
   * Retrieves the full detail of a single partner application for the
   * reviewer screen.
   *
   * @param applicationId Id of the Partner_Application__c to load.
   * @return A PartnerApplicationDetailDTO describing the application.
   */
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

  /**
   * Claims a partner application for the running user to review.
   *
   * @param applicationId Id of the Partner_Application__c to claim.
   */
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
