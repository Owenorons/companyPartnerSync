/*
 * Verifies PartnerPortalController's access boundary: a partner user with
 * a linked contact gets a dashboard back, while an internal user with no
 * partner contact is blocked with a handled exception.
 */
@IsTest
private class PartnerPortalControllerTest {
  @IsTest
  static void partnerUserGetsDashboardThroughController() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    Tenant_Config__mdt disabledConfig = new Tenant_Config__mdt(
      Enable_Deals__c = false,
      Enable_Leads__c = false,
      Enable_MDF__c = false
    );

    System.runAs(partnerUser) {
      TenantConfigService.setConfigForTest(disabledConfig);

      PartnerDashboardDTO dto = PartnerPortalController.getDashboard();

      System.assertEquals('Partner', dto.partnerName);
    }
  }

  @IsTest
  static void internalUserWithNoPartnerContactGetsHandledError() {
    User internalUser = TestUserFactory.createInternalUser();

    System.runAs(internalUser) {
      Boolean threw = false;

      try {
        PartnerPortalController.getDashboard();
      } catch (AuraHandledException ex) {
        threw = true;
      }

      System.assertEquals(
        true,
        threw,
        'A user with no linked partner contact should surface as a handled AuraHandledException.'
      );
    }
  }
}
