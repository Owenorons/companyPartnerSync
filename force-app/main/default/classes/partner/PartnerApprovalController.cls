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
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerApprovalController',
        'Unable to process partner approval decision.',
        'Unable to process application decision.',
        ex
      );
    }
  }

  @AuraEnabled
  public static void requestProvisioning(Id applicationId) {
    try {
      PartnerUserProvisioningService.requestProvisioning(applicationId);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerApprovalController',
        'Unable to request partner user provisioning.',
        'Unable to request partner access.',
        ex
      );
    }
  }
}
