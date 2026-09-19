/*
 * Covers LeadConversionService.convertLead(): new-vs-existing customer
 * account matching, the accepted-only gate, and current (not necessarily
 * intended) permission behavior for partner self-conversion.
 */
@IsTest
private class LeadConversionServiceTest {
  @IsTest
  static void internalUserConvertsLeadCreatingNewCustomerAccount() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;

    Lead lead = PartnerSyncTestDataFactory.lead(partner.Id, contact.Id);
    lead.Lead_Distribution_Status__c = 'Accepted';
    insert lead;

    User internalAdmin = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      internalAdmin.Id,
      'PartnerSync_Internal_Admin'
    );

    LeadConversionRequestDTO request = new LeadConversionRequestDTO();
    request.leadId = lead.Id;
    request.opportunityName = 'Customer Prospect Expansion';
    request.estimatedValue = 20000;
    request.estimatedCloseDate = Date.today().addDays(30);
    request.notes = 'Converted from accepted lead.';

    LeadConversionResultDTO result;

    System.runAs(internalAdmin) {
      enableLeadConversionFeatures();
      Test.startTest();
      result = LeadConversionService.convertLead(request);
      Test.stopTest();
    }

    System.assertEquals(
      true,
      result.customerAccountCreated,
      'No matching customer account existed, so a new one should be created.'
    );
    System.assertNotEquals(null, result.customerAccountId);
    System.assertNotEquals(null, result.opportunityId);
    System.assertNotEquals(null, result.dealRegistrationId);

    Opportunity opportunity = [
      SELECT Id, AccountId, Source_Lead__c, Partner_Account__c
      FROM Opportunity
      WHERE Id = :result.opportunityId
    ];
    System.assertEquals(lead.Id, opportunity.Source_Lead__c);
    System.assertEquals(result.customerAccountId, opportunity.AccountId);
    System.assertEquals(partner.Id, opportunity.Partner_Account__c);

    Deal_Registration__c deal = [
      SELECT Id, Opportunity__c, Source_Lead__c, Partner_Account__c
      FROM Deal_Registration__c
      WHERE Id = :result.dealRegistrationId
    ];
    System.assertEquals(result.opportunityId, deal.Opportunity__c);
    System.assertEquals(
      lead.Id,
      deal.Source_Lead__c,
      'The deal registration should carry the originating lead through the opportunity.'
    );
    System.assertEquals(partner.Id, deal.Partner_Account__c);

    Lead updatedLead = [
      SELECT Lead_Distribution_Status__c, Converted_Deal__c
      FROM Lead
      WHERE Id = :lead.Id
    ];
    System.assertEquals('Converted', updatedLead.Lead_Distribution_Status__c);
    System.assertEquals(
      result.dealRegistrationId,
      updatedLead.Converted_Deal__c
    );
  }

  @IsTest
  static void convertLeadReusesExistingCustomerAccountWhenLeadAlreadyLinked() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    Account existingCustomer = PartnerSyncTestDataFactory.customerAccount(
      'Existing Customer'
    );
    insert new List<Account>{ partner, existingCustomer };

    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;

    Lead lead = PartnerSyncTestDataFactory.lead(partner.Id, contact.Id);
    lead.Lead_Distribution_Status__c = 'Accepted';
    lead.Customer_Account__c = existingCustomer.Id;
    insert lead;

    User internalAdmin = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      internalAdmin.Id,
      'PartnerSync_Internal_Admin'
    );

    LeadConversionRequestDTO request = new LeadConversionRequestDTO();
    request.leadId = lead.Id;
    request.opportunityName = 'Existing Customer Expansion';
    request.estimatedValue = 8000;
    request.estimatedCloseDate = Date.today().addDays(15);

    LeadConversionResultDTO result;

    System.runAs(internalAdmin) {
      enableLeadConversionFeatures();
      result = LeadConversionService.convertLead(request);
    }

    System.assertEquals(
      false,
      result.customerAccountCreated,
      'The lead already pointed at a customer account, so no new one should be created.'
    );
    System.assertEquals(existingCustomer.Id, result.customerAccountId);
  }

  @IsTest
  static void convertLeadRejectsLeadNotInAcceptedStatus() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;

    Lead lead = PartnerSyncTestDataFactory.lead(partner.Id, contact.Id);
    insert lead;

    User internalAdmin = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      internalAdmin.Id,
      'PartnerSync_Internal_Admin'
    );

    LeadConversionRequestDTO request = new LeadConversionRequestDTO();
    request.leadId = lead.Id;
    request.opportunityName = 'Too Early Conversion';
    request.estimatedCloseDate = Date.today().addDays(30);

    System.runAs(internalAdmin) {
      enableLeadConversionFeatures();
      Boolean threw = false;

      try {
        LeadConversionService.convertLead(request);
      } catch (PartnerSyncHandledException ex) {
        threw = true;
        System.assert(ex.getMessage().contains('accepted'));
      }

      System.assertEquals(true, threw, 'Only accepted leads can be converted.');
    }
  }

  @IsTest
  static void convertLeadBlockedForPartnerUserUnderCurrentPermissionSet() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;

    Lead lead = PartnerSyncTestDataFactory.lead(partner.Id, contact.Id);
    lead.Lead_Distribution_Status__c = 'Accepted';
    insert lead;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);
    TestUserFactory.assignPermissionSet(
      partnerUser.Id,
      'PartnerSync_Partner_User'
    );

    LeadConversionRequestDTO request = new LeadConversionRequestDTO();
    request.leadId = lead.Id;
    request.opportunityName = 'Partner Self-Serve Conversion';
    request.estimatedCloseDate = Date.today().addDays(30);

    System.runAs(partnerUser) {
      enableLeadConversionFeatures();
      Boolean threw = false;

      try {
        LeadConversionService.convertLead(request);
      } catch (PartnerSyncHandledException ex) {
        threw = true;
      }

      System.assertEquals(
        true,
        threw,
        'PartnerSync_Partner_User currently has no create access on Opportunity, ' +
          'so a partner cannot self-convert even their own accepted lead. This test ' +
          'documents current behavior, not a deliberate ownership check.'
      );
    }
  }

  private static void enableLeadConversionFeatures() {
    TenantConfigService.setConfigForTest(
      new Tenant_Config__mdt(Enable_Deals__c = true, Enable_Leads__c = true)
    );
  }
}
