/**
 * Aura-enabled entry point for the internal exception-grant panel
 * embedded in the partner risk-approval workspace. Thin wrapper only:
 * delegates to PartnerReadinessLifecycleService and translates handled
 * exceptions into AuraHandledException. Compare to
 * PartnerRiskApprovalController, the equivalent entry point for the
 * surrounding approval-step queue.
 */
public with sharing class PartnerReadinessLifecycleController {
  /**
   * Lists the exceptions granted against an onboarding.
   *
   * @param onboardingId Id of the Partner_Onboarding__c to list exceptions for.
   * @return The onboarding's Partner_Exception__c records.
   */
  @AuraEnabled(cacheable=true)
  public static List<Partner_Exception__c> getExceptions(Id onboardingId) {
    try {
      return PartnerReadinessLifecycleService.getExceptions(onboardingId);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerReadinessLifecycleController',
        'Unable to load exceptions.',
        'Unable to load exceptions.',
        ex
      );
    }
  }

  /**
   * Grants a time-bounded exception waiving one activation gate.
   *
   * @param request The exception grant request.
   * @return The created Partner_Exception__c record.
   */
  @AuraEnabled
  public static Partner_Exception__c grantException(
    PartnerExceptionGrantDTO request
  ) {
    try {
      return PartnerReadinessLifecycleService.grantException(
        request?.onboardingId,
        request?.gate,
        request?.reason,
        request?.effectiveOn,
        request?.expiresOn
      );
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerReadinessLifecycleController',
        'Unable to grant exception.',
        'Unable to grant exception.',
        ex
      );
    }
  }

  /**
   * Revokes a previously granted exception.
   *
   * @param exceptionId Id of the Partner_Exception__c to revoke.
   * @param reason Reason the exception is being revoked.
   * @return The updated, now-Revoked Partner_Exception__c record.
   */
  @AuraEnabled
  public static Partner_Exception__c revokeException(
    Id exceptionId,
    String reason
  ) {
    try {
      return PartnerReadinessLifecycleService.revokeException(
        exceptionId,
        reason
      );
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerReadinessLifecycleController',
        'Unable to revoke exception.',
        'Unable to revoke exception.',
        ex
      );
    }
  }
}
