@IsTest
private class CoverageBusinessFlowTest {
  @IsTest
  static void partnerSubmitsAndReadsMdfRequestAndBudget() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('MDF Coverage');
    partner.MDF_Annual_Budget__c = 10000;
    partner.MDF_Used__c = 2500;
    insert partner;
    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;
    User partnerUser = TestUserFactory.createExternalUser(contact.Id);
    TestUserFactory.assignPermissionSet(
      partnerUser.Id,
      'PartnerSync_Partner_User'
    );

    System.runAs(partnerUser) {
      TenantConfigService.setConfigForTest(
        new Tenant_Config__mdt(Enable_MDF__c = true)
      );
      MDFRequestDTO request = new MDFRequestDTO();
      request.requestType = 'Webinar';
      request.campaignName = 'Coverage Campaign';
      request.campaignDescription = 'Meaningful MDF service coverage';
      request.requestedAmount = 1200;
      request.startDate = Date.today().addDays(1);
      request.endDate = Date.today().addDays(7);
      request.roiTarget = 25;

      MDFController.submitRequest(request);
      List<MDFListDTO> requests = MDFController.getMyRequests();
      Assert.areEqual(1, requests.size());
      Assert.areEqual('Coverage Campaign', requests[0].campaignName);

      MDFBudgetDTO budget = MDFController.getMyBudget();
      Assert.areEqual(10000, budget.annualBudget);
      Assert.areEqual(2500, budget.usedBudget);
      Assert.areEqual(7500, budget.remainingBudget);
    }
  }

  @IsTest
  static void internalManagerAssignsLeadAndPartnerReadsIt() {
    User manager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      manager.Id,
      'PartnerSync_Channel_Manager'
    );

    Account partner;
    Contact contact;
    Lead lead;
    System.runAs(manager) {
      partner = PartnerSyncTestDataFactory.partnerAccount('Lead Coverage');
      insert partner;
      contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
      insert contact;
      lead = new Lead(
        LastName = 'Coverage Lead',
        Company = 'Coverage Customer',
        Status = 'Open - Not Contacted',
        Email = 'lead-coverage@example.com'
      );
      insert lead;

      TenantConfigService.setConfigForTest(
        new Tenant_Config__mdt(Enable_Leads__c = true, Lead_SLA_Hours__c = 48)
      );
      LeadAssignmentRequestDTO request = new LeadAssignmentRequestDTO();
      request.leadId = lead.Id;
      request.partnerAccountId = partner.Id;
      request.partnerContactId = contact.Id;
      request.slaHoursOverride = 12;
      request.notes = 'Coverage assignment';
      LeadDistributionController.assignLeadToPartner(request);

      Lead assigned = [
        SELECT
          Partner_Account__c,
          Partner_Contact__c,
          Lead_Distribution_Status__c,
          Response_SLA_Hours__c,
          SLA_Deadline__c
        FROM Lead
        WHERE Id = :lead.Id
      ];
      Assert.areEqual(partner.Id, assigned.Partner_Account__c);
      Assert.areEqual(contact.Id, assigned.Partner_Contact__c);
      Assert.areEqual('Assigned', assigned.Lead_Distribution_Status__c);
      Assert.areEqual(12, assigned.Response_SLA_Hours__c);
      Assert.isNotNull(assigned.SLA_Deadline__c);
    }

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);
    TestUserFactory.assignPermissionSet(
      partnerUser.Id,
      'PartnerSync_Partner_User'
    );
    System.runAs(partnerUser) {
      TenantConfigService.setConfigForTest(
        new Tenant_Config__mdt(Enable_Leads__c = true)
      );
      List<LeadDistributionDTO> myLeads = LeadDistributionController.getMyLeads();
      Assert.areEqual(1, myLeads.size());
      Assert.areEqual(lead.Id, myLeads[0].leadId);
      Assert.areEqual('Assigned', myLeads[0].status);

      LeadDecisionRequestDTO decision = new LeadDecisionRequestDTO();
      decision.leadId = lead.Id;
      decision.decision = 'Accepted';
      decision.notes = 'Partner accepted through the portal controller';
      LeadDistributionController.processDecision(decision);
      Lead accepted = [
        SELECT Lead_Distribution_Status__c, Accepted_Date__c
        FROM Lead
        WHERE Id = :lead.Id
      ];
      Assert.areEqual('Accepted', accepted.Lead_Distribution_Status__c);
      Assert.isNotNull(accepted.Accepted_Date__c);
    }
  }
}
