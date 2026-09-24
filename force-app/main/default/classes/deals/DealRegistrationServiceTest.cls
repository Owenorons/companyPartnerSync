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
    TestUserFactory.assignPermissionSet(
      partnerUser.Id,
      'PartnerSync_Partner_User'
    );
    if (
      !PartnerAccessService.testPartnerAccountIdsByUser.containsKey(
        partnerUser.Id
      )
    ) {
      insert new OpportunityShare(
        OpportunityId = opportunity.Id,
        UserOrGroupId = partnerUser.Id,
        OpportunityAccessLevel = 'Read',
        RowCause = Schema.OpportunityShare.RowCause.Manual
      );
    }

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

    System.assertEquals(
      1,
      [
        SELECT COUNT()
        FROM Usage_Metric__c
        WHERE
          Partner_Account__c = :partner.Id
          AND Metric_Type__c = 'Deal Submitted'
      ]
    );
  }

  @IsTest
  static void getDealDetailReturnsDealForOwningPartner() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Detail Partner'
    );
    insert partner;

    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Detail Customer'
    );
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
    TestUserFactory.assignPermissionSet(
      partnerUser.Id,
      'PartnerSync_Partner_User'
    );
    if (
      !PartnerAccessService.testPartnerAccountIdsByUser.containsKey(
        partnerUser.Id
      )
    ) {
      insert new OpportunityShare(
        OpportunityId = opportunity.Id,
        UserOrGroupId = partnerUser.Id,
        OpportunityAccessLevel = 'Read',
        RowCause = Schema.OpportunityShare.RowCause.Manual
      );
    }

    Tenant_Config__mdt config = new Tenant_Config__mdt(
      Enable_Deals__c = true,
      Max_Open_Deals_Per_Partner__c = 5
    );

    Test.startTest();
    System.runAs(partnerUser) {
      TenantConfigService.setConfigForTest(config);

      DealRegistrationResultDTO created = DealRegistrationService.createDealRegistration(
        buildRequest(opportunity.Id)
      );

      DealRegistrationDetailDTO detail = DealRegistrationService.getDealDetail(
        created.dealRegistrationId
      );

      System.assertEquals(created.dealRegistrationId, detail.dealId);
      System.assertEquals('Need partner coverage', detail.businessProblem);
      System.assertEquals('Joint solution', detail.proposedSolution);
      System.assertEquals(25000, detail.dealValue);
      System.assertNotEquals(null, detail.events);
    }
    Test.stopTest();
  }

  @IsTest
  static void getDealDetailRejectsAnotherPartner() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Owning Partner'
    );
    insert partner;

    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Owning Customer'
    );
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
    TestUserFactory.assignPermissionSet(
      partnerUser.Id,
      'PartnerSync_Partner_User'
    );
    if (
      !PartnerAccessService.testPartnerAccountIdsByUser.containsKey(
        partnerUser.Id
      )
    ) {
      insert new OpportunityShare(
        OpportunityId = opportunity.Id,
        UserOrGroupId = partnerUser.Id,
        OpportunityAccessLevel = 'Read',
        RowCause = Schema.OpportunityShare.RowCause.Manual
      );
    }

    Tenant_Config__mdt config = new Tenant_Config__mdt(
      Enable_Deals__c = true,
      Max_Open_Deals_Per_Partner__c = 5
    );

    Id dealId;
    System.runAs(partnerUser) {
      TenantConfigService.setConfigForTest(config);
      dealId = DealRegistrationService.createDealRegistration(
          buildRequest(opportunity.Id)
        )
        .dealRegistrationId;
    }

    Account otherPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Other Partner'
    );
    insert otherPartner;
    Contact otherContact = PartnerSyncTestDataFactory.partnerContact(
      otherPartner.Id
    );
    insert otherContact;
    User otherPartnerUser = TestUserFactory.createExternalUser(otherContact.Id);
    TestUserFactory.assignPermissionSet(
      otherPartnerUser.Id,
      'PartnerSync_Partner_User'
    );

    Test.startTest();
    System.runAs(otherPartnerUser) {
      try {
        DealRegistrationService.getDealDetail(dealId);
        System.assert(false, 'Expected an access failure.');
      } catch (Exception expected) {
        System.assert(true);
      }
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
    existingDeal.Customer_Name__c = 'Customer';
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
