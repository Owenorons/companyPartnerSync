/**
 * Aura-enabled entry point for the partner-facing consent capture LWC.
 * Thin wrapper only: delegates to PartnerConsentService and translates
 * handled exceptions into AuraHandledException. Compare to
 * PartnerDocumentController, the equivalent partner-facing entry point
 * for onboarding documents.
 */
public with sharing class PartnerConsentController {
  /**
   * Loads the running partner's own consent records.
   *
   * @return The caller's own Partner_Consent__c records.
   */
  @AuraEnabled(cacheable=true)
  public static List<Partner_Consent__c> getMyConsents() {
    try {
      return PartnerConsentService.getMyConsents();
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerConsentController',
        'Unable to load consents.',
        'Unable to load consents.',
        ex
      );
    }
  }

  /**
   * Records the running partner's acceptance of a policy version.
   *
   * @param policyKey Key identifying the policy being accepted.
   * @param policyVersion Version of the policy being accepted.
   * @return The created or re-confirmed Partner_Consent__c record.
   */
  @AuraEnabled
  public static Partner_Consent__c acceptConsent(
    String policyKey,
    String policyVersion
  ) {
    try {
      return PartnerConsentService.acceptConsent(policyKey, policyVersion);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerConsentController',
        'Unable to record consent.',
        'Unable to record consent.',
        ex
      );
    }
  }

  /**
   * Revokes one of the running partner's own consent records.
   *
   * @param consentId Id of the Partner_Consent__c to revoke.
   * @return The updated, now-Revoked Partner_Consent__c record.
   */
  @AuraEnabled
  public static Partner_Consent__c revokeConsent(Id consentId) {
    try {
      return PartnerConsentService.revokeConsent(consentId);
    } catch (Exception ex) {
      throw ControllerExceptionMapper.toAura(
        'PartnerConsentController',
        'Unable to revoke consent.',
        'Unable to revoke consent.',
        ex
      );
    }
  }
}
