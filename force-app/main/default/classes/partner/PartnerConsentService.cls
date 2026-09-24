/**
 * Partner self-service consent capture: versioned policy acceptance and
 * revocation for the running partner's own onboarding. Scoped to the
 * caller's own partner account/contact, matching
 * PartnerDocumentService.getMyRequirements().
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class PartnerConsentService {
  /**
   * Loads the running partner's own consent records (for their most
   * recently created onboarding).
   *
   * @return The caller's own Partner_Consent__c records, most recent first.
   */
  public static List<Partner_Consent__c> getMyConsents() {
    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();
    List<Partner_Onboarding__c> onboardings = [
      SELECT Id
      FROM Partner_Onboarding__c
      WHERE Partner_Account__c = :partnerAccountId
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    if (onboardings.isEmpty()) {
      return new List<Partner_Consent__c>();
    }
    return [
      SELECT
        Id,
        Policy_Key__c,
        Policy_Version__c,
        Status__c,
        Accepted_On__c,
        Revoked_On__c
      FROM Partner_Consent__c
      WHERE Onboarding__c = :onboardings[0].Id
      ORDER BY CreatedDate DESC
    ];
  }

  /**
   * Records the running partner's acceptance of a policy version against
   * their own onboarding. Idempotent: accepting the same policy key and
   * version again re-confirms it as Active rather than creating a
   * duplicate record.
   *
   * @param policyKey Key identifying the policy being accepted.
   * @param policyVersion Version of the policy being accepted.
   * @return The created or re-confirmed Partner_Consent__c record.
   */
  public static Partner_Consent__c acceptConsent(
    String policyKey,
    String policyVersion
  ) {
    if (String.isBlank(policyKey) || String.isBlank(policyVersion)) {
      throw new PartnerSyncHandledException(
        'Policy key and version are required.'
      );
    }
    Id partnerAccountId = PartnerAccessService.getCurrentPartnerAccountId();
    Contact contact = PartnerAccessService.getCurrentPartnerContact();
    List<Partner_Onboarding__c> onboardings = [
      SELECT Id
      FROM Partner_Onboarding__c
      WHERE Partner_Account__c = :partnerAccountId
      ORDER BY CreatedDate DESC
      LIMIT 1
    ];
    if (onboardings.isEmpty()) {
      throw new PartnerSyncHandledException(
        'No onboarding was found for the current partner.'
      );
    }
    Partner_Consent__c consent = new Partner_Consent__c(
      Onboarding__c = onboardings[0].Id,
      Consent_Key__c = onboardings[0].Id +
        ':' +
        policyKey +
        ':' +
        policyVersion,
      Policy_Key__c = policyKey,
      Policy_Version__c = policyVersion,
      Accepted_By__c = contact.Id,
      Accepted_On__c = System.now(),
      Status__c = 'Active',
      Revoked_On__c = null
    );
    Database.upsert(
      consent,
      Partner_Consent__c.Fields.Consent_Key__c,
      AccessLevel.SYSTEM_MODE
    );
    return consent;
  }

  /**
   * Revokes one of the running partner's own consent records.
   *
   * @param consentId Id of the Partner_Consent__c to revoke.
   * @return The updated, now-Revoked Partner_Consent__c record.
   */
  public static Partner_Consent__c revokeConsent(Id consentId) {
    Contact contact = PartnerAccessService.getCurrentPartnerContact();
    Partner_Consent__c consent = [
      SELECT Id, Accepted_By__c, Status__c
      FROM Partner_Consent__c
      WHERE Id = :consentId
      WITH SYSTEM_MODE
      LIMIT 1
      FOR UPDATE
    ];
    if (consent.Accepted_By__c != contact.Id) {
      throw new PartnerSyncHandledException(
        'You can only revoke your own consent.'
      );
    }
    consent.Status__c = 'Revoked';
    consent.Revoked_On__c = System.now();
    Database.update(consent, AccessLevel.SYSTEM_MODE);
    return consent;
  }
}
