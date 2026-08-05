/*
 * Coverage for DealRegistrationService.createDealRegistration: the tenant
 * feature gate, the per-partner open-deal cap, and the baseline happy path
 * they sit on top of.
 */
@IsTest
private class DealRegistrationServiceTest {
  private static DealRegistrationRequestDTO buildRequest(Id opportunityId) {
    DealRegistrationRequestDTO request = new DealRegistrationRequestDTO();
    request.opportunityId = opportunityId;
    request.businessProblem = 'Need partner coverage';
    request.proposedSolution = 'Joint solution';
    request.estimatedRevenue = 25000;
    request.estimatedCloseDate = Date.today().addDays(30);
    return request;
  }

  @IsTest
  static void createDealRegistrationSucceedsWhenUnderCap() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    contact.Can_Submit_Deals__c = true;
    insert contact;

    Opportunity opportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      partner.Id,
      contact.Id
    );
    insert opportunity;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    Tenant_Config__mdt config = new Tenant_Config__mdt(
      Enable_Deals__c = true,
      Max_Open_Deals_Per_Partner__c = 5
    );

    Test.startTest();
    System.runAs(partnerUser) {
      TenantConfigService.setConfigForTest(config);

      DealRegistrationResultDTO result = DealRegistrationService.createDealRegistration(
        buildRequest(opportunity.Id)
      );

      System.assertNotEquals(null, result.dealRegistrationId);
    }
    Test.stopTest();
  }

  @IsTest
  static void createDealRegistrationBlockedWhenPartnerAtOpenDealCap() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    contact.Can_Submit_Deals__c = true;
    insert contact;

    // Occupies the partner's one allowed open-deal slot.
    Deal_Registration__c existingDeal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      partner.Id,
      contact.Id,
      null
    );
    insert existingDeal;

    Opportunity opportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      partner.Id,
      contact.Id
    );
    insert opportunity;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    Tenant_Config__mdt config = new Tenant_Config__mdt(
      Enable_Deals__c = true,
      Max_Open_Deals_Per_Partner__c = 1
    );

    Test.startTest();
    System.runAs(partnerUser) {
      TenantConfigService.setConfigForTest(config);

      Boolean threw = false;

      try {
        DealRegistrationService.createDealRegistration(
          buildRequest(opportunity.Id)
        );
      } catch (PartnerSyncHandledException ex) {
        threw = true;
      }

      System.assertEquals(
        true,
        threw,
        'A partner already at the configured open-deal cap should be blocked from registering another.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void createDealRegistrationBlockedWhenDealsDisabled() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    contact.Can_Submit_Deals__c = true;
    insert contact;

    Opportunity opportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      partner.Id,
      contact.Id
    );
    insert opportunity;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    Tenant_Config__mdt config = new Tenant_Config__mdt(Enable_Deals__c = false);

    Test.startTest();
    System.runAs(partnerUser) {
      TenantConfigService.setConfigForTest(config);

      Boolean threw = false;

      try {
        DealRegistrationService.createDealRegistration(
          buildRequest(opportunity.Id)
        );
      } catch (PartnerSyncHandledException ex) {
        threw = true;
      }

      System.assertEquals(
        true,
        threw,
        'Deal registration should be blocked when the tenant has Deals disabled.'
      );
    }
    Test.stopTest();
  }
}
