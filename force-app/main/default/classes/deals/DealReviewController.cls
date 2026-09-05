/*
 * Aura-enabled entry point for the internal deal review/approval LWC
 * (queue, detail, decision). Thin wrapper only: delegates to
 * DealReviewService and translates handled exceptions into
 * AuraHandledException. Compare to DealRegistrationController, the
 * equivalent entry point for the partner-facing submission flow.
 */
public with sharing class DealReviewController {
  @AuraEnabled(cacheable=true)
  public static List<DealReviewListDTO> getReviewQueue() {
    try {
      return DealReviewService.getReviewQueue();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealReviewController',
        'Unable to load deal review queue.',
        'Unable to load deal review queue.',
        ex
      );
    }
  }

  @AuraEnabled(cacheable=true)
  public static DealReviewDetailDTO getReviewDetail(Id dealId) {
    try {
      return DealReviewService.getReviewDetail(dealId);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealReviewController',
        'Unable to load deal review detail.',
        'Unable to load deal review detail.',
        ex
      );
    }
  }

  @AuraEnabled
  public static void processDecision(DealReviewDecisionDTO request) {
    try {
      DealReviewService.processDecision(request);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealReviewController',
        'Unable to process deal review decision.',
        'Unable to process deal review decision.',
        ex
      );
    }
  }
}
