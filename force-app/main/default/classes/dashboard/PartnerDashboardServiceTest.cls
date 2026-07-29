/*
 * Verifies PartnerDashboardService's per-tenant feature gating: counts
 * and alerts (lead, conflict, low-budget) appear when Deals/Leads/MDF are
 * enabled, and all fall back to zero/empty when disabled.
 */
@IsTest
private class PartnerDashboardServiceTest {
  @IsTest
  static void partnerSeesOwnCountsAndAlertsWhenFeaturesEnabled() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    partner.MDF_Annual_Budget__c = 10000;
    partner.MDF_Used__c = 9000;
    insert partner;

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    Tenant_Config__mdt enabledConfig = new Tenant_Config__mdt(
      Enable_Deals__c = true,
      Enable_Leads__c = true,
      Enable_MDF__c = true
    );

    Test.startTest();
    System.runAs(partnerUser) {
      TenantConfigService.setConfigForTest(enabledConfig);

      // Inserted as partnerUser so they own these records and can read them
      // back regardless of whether this org's partner Sharing Set has been
      // configured yet — see docs/post-install-sharing-setup.md.
      Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
        customer.Id,
        partner.Id,
        contact.Id,
        null
      );
      deal.Conflict_Status__c = 'Potential Conflict';
      insert deal;

      Lead lead = PartnerSyncTestDataFactory.lead(partner.Id, contact.Id);
      lead.Lead_Distribution_Status__c = 'Assigned';
      insert lead;

      MDF_Request__c mdfRequest = PartnerSyncTestDataFactory.mdfRequest(
        partner.Id,
        contact.Id
      );
      insert mdfRequest;

      PartnerDashboardDTO dto = PartnerDashboardService.getDashboard();

      System.assertEquals('Partner', dto.partnerName);
      System.assertEquals('Active', dto.partnerStatus);
      System.assertEquals('Gold', dto.partnerTier);
      System.assertEquals(1, dto.openDealCount);
      System.assertEquals(1, dto.assignedLeadCount);
      System.assertEquals(1, dto.openMdfCount);
      System.assertEquals(
        3,
        dto.alerts.size(),
        'A lead alert, conflict alert, and low-budget alert should all fire.'
      );
    }
    Test.stopTest();
  }

  @IsTest
  static void partnerSeesZeroCountsWhenFeaturesDisabled() {
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

      PartnerDashboardDTO dto = PartnerDashboardService.getDashboard();

      System.assertEquals(0, dto.openDealCount);
      System.assertEquals(0, dto.assignedLeadCount);
      System.assertEquals(0, dto.openMdfCount);
      System.assertEquals(
        0,
        dto.alerts.size(),
        'No alerts should fire for disabled feature areas.'
      );
    }
  }
}
