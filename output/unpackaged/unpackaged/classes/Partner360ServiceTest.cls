@IsTest
private class Partner360ServiceTest {
  @IsTest
  static void internalManagerSeesPartnerLifecycleAndCommercialSummary() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('360 Partner');
    partner.Partner_ID__c = 'P-360';
    partner.Partner_Status__c = 'Active';
    insert partner;
    Partner_Application__c application = new Partner_Application__c(
      Name = '360 Partner',
      Company_Name__c = '360 Partner',
      Business_Email__c = '360@example.test',
      Application_Status__c = 'Approved'
    );
    insert application;
    Partner_Onboarding__c onboarding = new Partner_Onboarding__c(
      Application__c = application.Id,
      Partner_Account__c = partner.Id,
      Onboarding_Key__c = application.Id,
      Status__c = 'Active',
      Current_Stage__c = 'Active',
      Activation_Gate_Status__c = 'Ready',
      Version_Number__c = 1
    );
    insert onboarding;
    insert new Partner_Lifecycle_Event__c(
      Onboarding__c = onboarding.Id,
      Event_Type__c = 'Partner Activated',
      Stage__c = 'Active',
      Summary__c = 'Activation completed.',
      Occurred_On__c = System.now(),
      Idempotency_Key__c = onboarding.Id + ':360'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      '360 Customer'
    );
    insert customer;
    insert PartnerSyncTestDataFactory.deal(customer.Id, partner.Id, null, null);
    insert PartnerSyncTestDataFactory.mdfRequest(partner.Id, null);

    User manager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      manager.Id,
      'PartnerSync_Channel_Manager'
    );
    System.runAs(manager) {
      Partner360DTO dto = Partner360Service.getSummary(partner.Id);
      System.assertEquals('360 Partner', dto.partnerName);
      System.assertEquals('P-360', dto.partnerId);
      System.assertEquals(onboarding.Id, dto.onboardingId);
      System.assertEquals(1, dto.openDealCount);
      System.assertEquals(1, dto.openMdfCount);
      System.assertEquals(1, dto.recentEvents.size());
      System.assertEquals(
        partner.Id,
        Partner360Controller.getSummary(partner.Id).partnerAccountId
      );
    }
  }

  @IsTest
  static void partnerUserCannotUseInternalPartner360() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('External 360');
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    User externalUser = TestUserFactory.createExternalUser(contact.Id);
    System.runAs(externalUser) {
      try {
        Partner360Service.getSummary(partner.Id);
        System.assert(false, 'Expected internal-user enforcement.');
      } catch (PartnerSyncHandledException expected) {
        System.assert(expected.getMessage().contains('internal'));
      }
    }
  }

  @IsTest
  static void controllerConvertsMissingPartnerToHandledError() {
    User manager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      manager.Id,
      'PartnerSync_Channel_Manager'
    );
    System.runAs(manager) {
      try {
        Partner360Controller.getSummary(null);
        System.assert(false, 'Expected a handled controller error.');
      } catch (AuraHandledException expected) {
        System.assertNotEquals(null, expected);
      }
    }
  }

  @IsTest
  static void controllerConvertsUnexpectedFailureToSafeError() {
    User manager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      manager.Id,
      'PartnerSync_Channel_Manager'
    );
    System.runAs(manager) {
      Partner360Controller.simulateUnexpectedFailure = true;
      try {
        Partner360Controller.getSummary(null);
        System.assert(false, 'Expected a safe controller error.');
      } catch (AuraHandledException expected) {
        System.assertNotEquals(null, expected);
      } finally {
        Partner360Controller.simulateUnexpectedFailure = false;
      }
    }
  }
}
