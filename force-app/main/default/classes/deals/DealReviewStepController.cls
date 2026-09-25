/**
 * Aura-enabled entry point for the "my pending deal review steps" LWC
 * (queue, detail, action). Thin wrapper only: delegates to
 * DealReviewStepWorkspaceService and translates handled exceptions into
 * AuraHandledException. Compare to DealReviewController, which handles the
 * deal-level review queue and final approve/reject decision - this
 * controller is for working the individual Deal_Review__c checklist items
 * that queue is built from.
 */
public with sharing class DealReviewStepController {
  /**
   * Loads the running user's pending deal review steps.
   *
   * @return Row shapes for steps the running user can work.
   */
  @AuraEnabled(cacheable=true)
  public static List<DealReviewStepListDTO> getMyPendingSteps() {
    try {
      return DealReviewStepWorkspaceService.getMyPendingSteps();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealReviewStepController',
        'Unable to load pending deal review steps.',
        'Unable to load pending deal review steps.',
        ex
      );
    }
  }

  /**
   * Loads the full detail for a single deal review step.
   *
   * @param reviewId Id of the review step to load.
   * @return The full detail DTO for the step.
   */
  @AuraEnabled(cacheable=true)
  public static DealReviewStepDetailDTO getStepDetail(Id reviewId) {
    try {
      return DealReviewStepWorkspaceService.getStepDetail(reviewId);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealReviewStepController',
        'Unable to load deal review step detail.',
        'Unable to load deal review step detail.',
        ex
      );
    }
  }

  /**
   * Processes an action on a pending deal review step.
   *
   * @param request The action request.
   */
  @AuraEnabled
  public static void decide(DealReviewStepDecisionDTO request) {
    try {
      DealReviewStepWorkspaceService.decide(request);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealReviewStepController',
        'Unable to process deal review step action.',
        'Unable to process deal review step action.',
        ex
      );
    }
  }
}
