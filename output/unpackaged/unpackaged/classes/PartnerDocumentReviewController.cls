/**
 * Aura-enabled entry point for the internal document review LWC (queue,
 * decision). Thin wrapper only: delegates to PartnerDocumentService and
 * translates handled exceptions into AuraHandledException. Compare to
 * PartnerRiskApprovalController, the equivalent entry point for the
 * internal risk-approval workspace.
 */
public with sharing class PartnerDocumentReviewController {
  /**
   * Loads the internal document review queue for reviewers with the
   * required review permission.
   *
   * @return Row shapes for documents awaiting or already through review.
   */
  @AuraEnabled(cacheable=true)
  public static List<PartnerDocumentReviewListDTO> getReviewQueue() {
    try {
      return PartnerDocumentService.getReviewQueue();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerDocumentReviewController',
        'Unable to load document review queue.',
        'Unable to load document review queue.',
        ex
      );
    }
  }

  /**
   * Processes an internal reviewer's decision on a submitted document.
   *
   * @param request The reviewer's decision request.
   */
  @AuraEnabled
  public static void reviewDocument(PartnerDocumentReviewDecisionDTO request) {
    try {
      PartnerDocumentService.reviewDocument(
        request?.documentId,
        request?.outcome,
        request?.reason,
        String.valueOf(request?.documentId) +
          ':' +
          String.valueOf(request?.outcome)
      );
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerDocumentReviewController',
        'Unable to process document review decision.',
        'Unable to process document review decision.',
        ex
      );
    }
  }
}
