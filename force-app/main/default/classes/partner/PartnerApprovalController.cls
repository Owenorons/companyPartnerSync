/*
 * Aura-enabled entry point for the internal reviewer UI's approve/reject
 * action on a partner application. Delegates all decisioning logic to
 * PartnerOnboardingService; this class only exists to translate handled vs.
 * unhandled exceptions into what the LWC is allowed to see.
 */
public with sharing class PartnerApprovalController {
  @AuraEnabled
  public static void processDecision(PartnerApprovalRequestDTO request) {
    try {
      PartnerOnboardingService.processDecision(request);
    } catch (PartnerSyncHandledException ex) {
      throw new AuraHandledException(ex.getMessage());
    } catch (Exception ex) {
      LoggingService.error(
        'PartnerApprovalController',
        'Unable to process partner approval decision.',
        ex
      );

      throw new AuraHandledException('Unable to process application decision.');
    }
  }
}
