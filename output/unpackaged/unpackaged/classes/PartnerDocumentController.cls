/**
 * Aura-enabled entry point for the partner-facing onboarding documents LWC
 * (requirement list, submission). Thin wrapper only: delegates to
 * PartnerDocumentService and translates handled exceptions into
 * AuraHandledException. Compare to MDFController, the equivalent
 * partner-facing entry point for MDF requests.
 */
public with sharing class PartnerDocumentController {
  /**
   * Loads the running partner's own document requirements.
   *
   * @return Row shapes for the caller's own document requirements.
   */
  @AuraEnabled(cacheable=true)
  public static List<PartnerDocumentRequirementListDTO> getMyRequirements() {
    try {
      return PartnerDocumentService.getMyRequirements();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerDocumentController',
        'Unable to load document requirements.',
        'Unable to load document requirements.',
        ex
      );
    }
  }

  /**
   * Submits a partner's document against a requirement. The submission key
   * is derived from the requirement and content document so retrying the
   * same upload does not create a duplicate submission.
   *
   * @param request The submission details, including the uploaded file's ContentDocument Id.
   */
  @AuraEnabled
  public static void submitDocument(PartnerDocumentSubmissionDTO request) {
    try {
      PartnerDocumentService.submitDocument(
        request?.requirementId,
        request?.contentDocumentId,
        String.valueOf(request?.requirementId) +
          ':' +
          String.valueOf(request?.contentDocumentId),
        request?.confidentiality
      );
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerDocumentController',
        'Unable to submit document.',
        'Unable to submit document.',
        ex
      );
    }
  }
}
