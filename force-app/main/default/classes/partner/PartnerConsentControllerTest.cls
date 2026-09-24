@IsTest
private class PartnerConsentControllerTest {
  private static Partner_Onboarding__c onboarding(Id partnerAccountId) {
    Partner_Application__c application = new Partner_Application__c(
      Name = 'Consent Portal Applicant',
      Company_Name__c = 'Consent Portal Applicant',
      Business_Email__c = 'consent-portal-' +
        System.now().getTime() +
        '@example.com',
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
  static void acceptAndRevokeConsentAsRunningPartnerUser() {
    Account partnerAccount = PartnerSyncTestDataFactory.partnerAccount(
      'Consent Portal Partner'
    );
    insert partnerAccount;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(
      partnerAccount.Id
    );
    insert contact;
    onboarding(partnerAccount.Id);

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);
    TestUserFactory.assignPermissionSet(
      partnerUser.Id,
      'PartnerSync_Partner_User'
    );
    TestUserFactory.assignPermissionSet(
      partnerUser.Id,
      'PartnerSync_Partner_Base_Data'
    );

    System.runAs(partnerUser) {
      Partner_Consent__c accepted = PartnerConsentController.acceptConsent(
        'PARTNER-TERMS',
        '2026-1'
      );
      Assert.areEqual('Active', accepted.Status__c);

      List<Partner_Consent__c> mine = PartnerConsentController.getMyConsents();
      Assert.areEqual(1, mine.size());

      Partner_Consent__c revoked = PartnerConsentController.revokeConsent(
        accepted.Id
      );
      Assert.areEqual('Revoked', revoked.Status__c);
    }
  }
}
