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
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'DealReviewController',
        'Unable to load deal review queue.',
        ex
      );

      throw new AuraHandledException('Unable to load deal review queue.');
    }
  }

  @AuraEnabled(cacheable=true)
  public static DealReviewDetailDTO getReviewDetail(Id dealId) {
    try {
      return DealReviewService.getReviewDetail(dealId);
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'DealReviewController',
        'Unable to load deal review detail.',
        ex
      );

      throw new AuraHandledException('Unable to load deal review detail.');
    }
  }

  @AuraEnabled
  public static void processDecision(DealReviewDecisionDTO request) {
    try {
      DealReviewService.processDecision(request);
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'DealReviewController',
        'Unable to process deal review decision.',
        ex
      );

      throw new AuraHandledException('Unable to process deal review decision.');
    }
  }
}
