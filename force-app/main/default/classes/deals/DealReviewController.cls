/**
 * Aura-enabled entry point for the internal deal review/approval LWC
 * (queue, detail, decision). Thin wrapper only: delegates to
 * DealReviewService and translates handled exceptions into
 * AuraHandledException. Compare to DealRegistrationController, the
 * equivalent entry point for the partner-facing submission flow.
 */
public with sharing class DealReviewController {
  /**
   * Loads the internal review queue for reviewers with permission to view all deals.
   *
   * @return Row shapes for deals awaiting or already through review.
   */
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

  /**
   * Loads the full review detail (including conflicts, computed risk, and per-decision
   * permission flags) for a single deal.
   *
   * @param dealId Id of the deal registration to load.
   * @return The full review detail DTO for the deal.
   */
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

  /**
   * Overrides a deal's attribution classification.
   *
   * @param dealId Id of the deal registration to update.
   * @param attributionType The corrected classification ('Partner-Sourced' or 'Co-Sell').
   */
  @AuraEnabled
  public static void overrideAttribution(Id dealId, String attributionType) {
    try {
      DealReviewService.overrideAttribution(dealId, attributionType);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'DealReviewController',
        'Unable to update deal attribution.',
        'Unable to update deal attribution.',
        ex
      );
    }
  }

  /**
   * Processes an internal reviewer's decision on a deal.
   *
   * @param request The reviewer's decision request.
   */
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
