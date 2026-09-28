/*
 * Covers RenewalOpportunityCommandService.createOpportunityForRenewal:
 * creates and links a new Opportunity via the reused Sprint 39
 * DealOpportunityCommandService.createOpportunityForDeal(), no new
 * Opportunity-integration layer.
 */
@IsTest
private class RenewalOpportunityCommandServiceTest {
  @IsTest
  static void createsAndLinksAnOpportunityViaTheReusedSprint39Command() {
    Fixture fixture = createFixture();
    User internalUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      internalUser.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Create_Deal_Opportunity',
      true
    );
    DealOpportunityCommandService.testPolicyOverride = new Deal_Opportunity_Policy__mdt(
      Creation_Mode__c = 'Create New'
    );

    Partner_Renewal__c updated;
    System.runAs(internalUser) {
      RenewalCommand command = new RenewalCommand();
      command.renewalId = fixture.renewal.Id;
      command.expectedVersion = 0;
      updated = RenewalOpportunityCommandService.createOpportunityForRenewal(
        command
      );
    }

    Assert.isNotNull(updated.Current_Opportunity__c);
    Assert.areEqual(fixture.deal.Id, updated.Current_Deal__c);
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Renewal Opportunity Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Renewal Opportunity Customer'
    );
    insert new List<Account>{ partner, customer };

    fixture.deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      partner.Id,
      null,
      null
    );
    fixture.deal.Status__c = 'Approved';
    insert fixture.deal;

    Customer_Success_Engagement__c engagement = new Customer_Success_Engagement__c(
      Customer_Account__c = customer.Id,
      Primary_Partner__c = partner.Id,
      Status__c = 'Active',
      Health_Status__c = 'Not Assessed',
      Version_Number__c = 0
    );
    insert engagement;

    fixture.renewal = new Partner_Renewal__c(
      Customer_Success_Engagement__c = engagement.Id,
      Customer_Account__c = customer.Id,
      Original_Deal__c = fixture.deal.Id,
      Primary_Partner__c = partner.Id,
      Status__c = 'Approved',
      Renewal_Health__c = 'On Track',
      Version_Number__c = 0
    );
    insert fixture.renewal;

    return fixture;
  }

  private class Fixture {
    Deal_Registration__c deal;
    Partner_Renewal__c renewal;
  }
}
