/*
 * Covers LeadDistributionController's thin wrapper behavior for the new
 * distributeLead entry point: success and handled-exception translation.
 */
@IsTest
private class LeadDistributionControllerTest {
  @IsTest
  static void distributeLeadSucceedsThroughTheController() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;
    Lead lead = new Lead(
      LastName = 'Lead',
      Company = 'Customer Prospect',
      Lead_Distribution_Status__c = 'Pending'
    );
    insert lead;

    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      TenantConfigService.setConfigForTest(
        new Tenant_Config__mdt(Enable_Leads__c = true)
      );
      LeadDistributionController.distributeLead(lead.Id);
    }

    Assert.areEqual(
      1,
      [SELECT COUNT() FROM Partner_Lead_Assignment__c WHERE Lead__c = :lead.Id]
    );
  }

  @IsTest
  static void distributeLeadTranslatesFailuresToAuraHandledException() {
    User plainInternalUser = TestUserFactory.createInternalUser();

    System.runAs(plainInternalUser) {
      TenantConfigService.setConfigForTest(
        new Tenant_Config__mdt(Enable_Leads__c = true)
      );

      Boolean threw = false;
      try {
        LeadDistributionController.distributeLead(null);
      } catch (AuraHandledException expected) {
        threw = true;
      }

      Assert.isTrue(
        threw,
        'A user without lead-assignment permission should be blocked.'
      );
    }
  }
}
