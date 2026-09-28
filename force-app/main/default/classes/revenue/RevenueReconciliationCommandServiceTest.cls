/*
 * Covers RevenueReconciliationCommandService: resolve links the
 * reconciliation's revenue to the chosen candidate deal, and resolve
 * requires a candidate deal.
 */
@IsTest
private class RevenueReconciliationCommandServiceTest {
  @IsTest
  static void resolveLinksRevenueToTheChosenDeal() {
    Fixture fixture = createFixture();

    System.runAs(fixture.financeUser) {
      RevenueReconciliationCommand command = new RevenueReconciliationCommand();
      command.reconciliationId = fixture.reconciliation.Id;
      command.candidateDealId = fixture.deal.Id;
      command.resolutionReason = 'Confirmed with the partner directly.';

      RevenueReconciliationCommandService.resolve(command);
    }

    Assert.areEqual(
      'Resolved',
      [
        SELECT Status__c
        FROM Revenue_Reconciliation__c
        WHERE Id = :fixture.reconciliation.Id
      ]
      .Status__c
    );
    Deal_Revenue__c revenue = [
      SELECT Deal__c, Status__c
      FROM Deal_Revenue__c
      WHERE Id = :fixture.revenue.Id
    ];
    Assert.areEqual(fixture.deal.Id, revenue.Deal__c);
    Assert.areEqual('Validated', revenue.Status__c);
  }

  @IsTest
  static void resolveRequiresACandidateDeal() {
    Fixture fixture = createFixture();

    System.runAs(fixture.financeUser) {
      RevenueReconciliationCommand command = new RevenueReconciliationCommand();
      command.reconciliationId = fixture.reconciliation.Id;

      try {
        RevenueReconciliationCommandService.resolve(command);
        Assert.fail(
          'Expected a resolve without a candidate deal to be rejected.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('candidate'));
      }
    }
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.financeUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      fixture.financeUser.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Manage_Revenue_Reconciliation',
      true
    );

    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Reconciliation Customer'
    );
    insert customer;
    fixture.deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      null,
      null,
      null
    );
    insert fixture.deal;

    fixture.revenue = new Deal_Revenue__c(
      Revenue_Type__c = 'Booking',
      Source_Type__c = 'Manual',
      Status__c = 'Pending',
      Gross_Amount__c = 50000,
      Version_Number__c = 0
    );
    insert fixture.revenue;

    fixture.reconciliation = new Revenue_Reconciliation__c(
      Revenue__c = fixture.revenue.Id,
      Status__c = 'Open',
      Match_Method__c = 'Automatic'
    );
    insert fixture.reconciliation;

    return fixture;
  }

  private class Fixture {
    User financeUser;
    Deal_Registration__c deal;
    Deal_Revenue__c revenue;
    Revenue_Reconciliation__c reconciliation;
  }
}
