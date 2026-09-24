@IsTest
private class PartnerConsentServiceTest {
  private static Contact contact(Id partnerAccountId) {
    Contact contact = PartnerSyncTestDataFactory.partnerContact(
      partnerAccountId
    );
    insert contact;
    return contact;
  }

  private static Partner_Onboarding__c onboarding(Id partnerAccountId) {
    Partner_Application__c application = new Partner_Application__c(
      Name = 'Consent Applicant',
      Company_Name__c = 'Consent Applicant',
      Business_Email__c = 'consent-' + System.now().getTime() + '@example.com',
      Application_Status__c = 'Approved',
      Requested_Tier__c = 'Gold',
      Partner_Type__c = 'Reseller',
      Country__c = 'Australia'
    );
    insert application;
    Partner_Onboarding__c onboarding = new Partner_Onboarding__c(
      Application__c = application.Id,
      Onboarding_Key__c = String.valueOf(application.Id),
      Partner_Account__c = partnerAccountId,
      Status__c = 'Onboarding',
      Current_Stage__c = 'Readiness',
      Activation_Gate_Status__c = 'Blocked',
      Version_Number__c = 1
    );
    insert onboarding;
    return onboarding;
  }

  @IsTest
  static void acceptConsentIsIdempotentByPolicyKeyAndVersion() {
    Account partnerAccount = PartnerSyncTestDataFactory.partnerAccount(
      'Consent Partner'
    );
    insert partnerAccount;
    Contact partnerContact = contact(partnerAccount.Id);
    onboarding(partnerAccount.Id);

    PartnerAccessService.partnerAccountIdOverride = partnerAccount.Id;
    PartnerAccessService.partnerContactOverride = partnerContact;
    try {
      Partner_Consent__c first = PartnerConsentService.acceptConsent(
        'PARTNER-TERMS',
        '2026-1'
      );
      Partner_Consent__c second = PartnerConsentService.acceptConsent(
        'PARTNER-TERMS',
        '2026-1'
      );
      System.assertEquals(first.Id, second.Id);
      System.assertEquals('Active', second.Status__c);
      System.assertEquals(partnerContact.Id, second.Accepted_By__c);

      List<Partner_Consent__c> mine = PartnerConsentService.getMyConsents();
      System.assertEquals(1, mine.size());
    } finally {
      PartnerAccessService.partnerAccountIdOverride = null;
      PartnerAccessService.partnerContactOverride = null;
    }
  }

  @IsTest
  static void revokeConsentRejectsAnotherPartnersConsent() {
    Account partnerAccount = PartnerSyncTestDataFactory.partnerAccount(
      'Consent Owner Partner'
    );
    insert partnerAccount;
    Contact ownerContact = contact(partnerAccount.Id);
    onboarding(partnerAccount.Id);

    PartnerAccessService.partnerAccountIdOverride = partnerAccount.Id;
    PartnerAccessService.partnerContactOverride = ownerContact;
    Partner_Consent__c consent;
    try {
      consent = PartnerConsentService.acceptConsent('PARTNER-TERMS', '2026-1');
    } finally {
      PartnerAccessService.partnerAccountIdOverride = null;
      PartnerAccessService.partnerContactOverride = null;
    }

    Account otherAccount = PartnerSyncTestDataFactory.partnerAccount(
      'Other Consent Partner'
    );
    insert otherAccount;
    Contact otherContact = contact(otherAccount.Id);

    PartnerAccessService.partnerAccountIdOverride = otherAccount.Id;
    PartnerAccessService.partnerContactOverride = otherContact;
    try {
      try {
        PartnerConsentService.revokeConsent(consent.Id);
        System.assert(false, 'Expected an ownership failure.');
      } catch (PartnerSyncHandledException expected) {
        System.assert(expected.getMessage().contains('own consent'));
      }
    } finally {
      PartnerAccessService.partnerAccountIdOverride = null;
      PartnerAccessService.partnerContactOverride = null;
    }
  }

  @IsTest
  static void revokeConsentSetsRevokedStatusAndTimestamp() {
    Account partnerAccount = PartnerSyncTestDataFactory.partnerAccount(
      'Consent Revoke Partner'
    );
    insert partnerAccount;
    Contact partnerContact = contact(partnerAccount.Id);
    onboarding(partnerAccount.Id);

    PartnerAccessService.partnerAccountIdOverride = partnerAccount.Id;
    PartnerAccessService.partnerContactOverride = partnerContact;
    try {
      Partner_Consent__c consent = PartnerConsentService.acceptConsent(
        'PARTNER-TERMS',
        '2026-1'
      );
      Partner_Consent__c revoked = PartnerConsentService.revokeConsent(
        consent.Id
      );
      System.assertEquals('Revoked', revoked.Status__c);
      System.assertNotEquals(null, revoked.Revoked_On__c);
    } finally {
      PartnerAccessService.partnerAccountIdOverride = null;
      PartnerAccessService.partnerContactOverride = null;
    }
  }
}
