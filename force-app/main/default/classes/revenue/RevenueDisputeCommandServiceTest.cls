/*
 * Covers RevenueDisputeCommandService: open/resolve, and resolving a
 * dispute never directly changes the referenced revenue amount (doc
 * §41.43).
 */
@IsTest
private class RevenueDisputeCommandServiceTest {
  @IsTest
  static void opensAndResolvesADispute() {
    Fixture fixture = createFixture();

    RevenueDisputeCommand openCommand = new RevenueDisputeCommand();
    openCommand.partnerAccountId = fixture.partner.Id;
    openCommand.dealId = fixture.deal.Id;
    openCommand.revenueId = fixture.revenue.Id;
    openCommand.disputeType = 'Missing Revenue';
    openCommand.description = 'We sourced this deal but no revenue is showing.';

    Partner_Revenue_Dispute__c dispute = RevenueDisputeCommandService.open(
      openCommand
    );
    Assert.isNotNull(dispute.Id);
    Assert.areEqual('Open', dispute.Status__c);

    User resolver = internalResolver();
    System.runAs(resolver) {
      RevenueDisputeCommand resolveCommand = new RevenueDisputeCommand();
      resolveCommand.disputeId = dispute.Id;
      resolveCommand.resolution = 'Confirmed and revenue was reconciled.';
      RevenueDisputeCommandService.resolve(resolveCommand);
    }

    Assert.areEqual(
      'Resolved',
      [
        SELECT Status__c
        FROM Partner_Revenue_Dispute__c
        WHERE Id = :dispute.Id
      ]
      .Status__c
    );
    Assert.areEqual(
      50000,
      [
        SELECT Gross_Amount__c
        FROM Deal_Revenue__c
        WHERE Id = :fixture.revenue.Id
      ]
      .Gross_Amount__c,
      'Resolving a dispute must never itself change the referenced revenue amount.'
    );
  }

  private static User internalResolver() {
    User resolver = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      resolver.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Manage_Revenue_Reconciliation',
      true
    );
    return resolver;
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.partner = PartnerSyncTestDataFactory.partnerAccount(
      'Dispute Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Dispute Customer'
    );
    insert new List<Account>{ fixture.partner, customer };

    fixture.deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      fixture.partner.Id,
      null,
      null
    );
    fixture.deal.Status__c = 'Approved';
    insert fixture.deal;

    fixture.revenue = new Deal_Revenue__c(
      Deal__c = fixture.deal.Id,
      Revenue_Type__c = 'Booking',
      Source_Type__c = 'Manual',
      Status__c = 'Confirmed',
      Gross_Amount__c = 50000,
      Version_Number__c = 0
    );
    insert fixture.revenue;

    return fixture;
  }

  private class Fixture {
    Account partner;
    Deal_Registration__c deal;
    Deal_Revenue__c revenue;
  }
}
