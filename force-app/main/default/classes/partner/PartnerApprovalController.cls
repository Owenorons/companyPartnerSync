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
