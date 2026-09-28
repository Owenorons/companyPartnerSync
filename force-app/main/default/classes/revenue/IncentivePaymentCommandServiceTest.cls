/*
 * Covers IncentivePaymentCommandService: record marks the incentive Paid,
 * and reversal creates a compensating record without deleting history
 * (doc §41.41).
 */
@IsTest
private class IncentivePaymentCommandServiceTest {
  @IsTest
  static void recordMarksTheIncentivePaid() {
    Fixture fixture = createFixture();

    System.runAs(fixture.financeUser) {
      IncentivePaymentCommand command = new IncentivePaymentCommand();
      command.incentiveId = fixture.incentive.Id;
      command.amount = 4500;
      command.paymentReference = 'PAY-1001';
      command.paymentSystem = 'Manual';

      Partner_Incentive_Payment__c payment = IncentivePaymentCommandService.record(
        command
      );

      Assert.isNotNull(payment.Id);
      Assert.areEqual('Paid', payment.Status__c);
    }

    Partner_Incentive__c refreshed = [
      SELECT Status__c, Paid_Amount__c
      FROM Partner_Incentive__c
      WHERE Id = :fixture.incentive.Id
    ];
    Assert.areEqual('Paid', refreshed.Status__c);
    Assert.areEqual(4500, refreshed.Paid_Amount__c);
  }

  @IsTest
  static void reverseCreatesACompensatingRecordAndReturnsTheIncentiveToApproved() {
    Fixture fixture = createFixture();

    Partner_Incentive_Payment__c payment;
    System.runAs(fixture.financeUser) {
      IncentivePaymentCommand recordCommand = new IncentivePaymentCommand();
      recordCommand.incentiveId = fixture.incentive.Id;
      recordCommand.amount = 4500;
      payment = IncentivePaymentCommandService.record(recordCommand);

      IncentivePaymentCommand reverseCommand = new IncentivePaymentCommand();
      reverseCommand.paymentId = payment.Id;
      reverseCommand.reason = 'Payment sent to the wrong account.';
      Partner_Incentive_Payment__c compensating = IncentivePaymentCommandService.reverse(
        reverseCommand
      );

      Assert.areEqual(-4500, compensating.Amount__c);
      Assert.areEqual('Reversed', compensating.Status__c);
    }

    Assert.areEqual(
      'Reversed',
      [
        SELECT Status__c
        FROM Partner_Incentive_Payment__c
        WHERE Id = :payment.Id
      ]
      .Status__c,
      'The original payment record must still exist, marked Reversed - not deleted.'
    );
    Partner_Incentive__c refreshed = [
      SELECT Status__c, Paid_Amount__c
      FROM Partner_Incentive__c
      WHERE Id = :fixture.incentive.Id
    ];
    Assert.areEqual('Approved', refreshed.Status__c);
    Assert.areEqual(0, refreshed.Paid_Amount__c);
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
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Reverse_Incentive',
      true
    );

    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Payment Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Payment Customer'
    );
    insert new List<Account>{ partner, customer };

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      partner.Id,
      null,
      null
    );
    deal.Status__c = 'Approved';
    insert deal;

    fixture.incentive = new Partner_Incentive__c(
      Deal__c = deal.Id,
      Partner_Account__c = partner.Id,
      Incentive_Type__c = 'Commission',
      Status__c = 'Approved',
      Calculated_Amount__c = 4500,
      Approved_Amount__c = 4500,
      Version_Number__c = 0
    );
    insert fixture.incentive;

    return fixture;
  }

  private class Fixture {
    User financeUser;
    Partner_Incentive__c incentive;
  }
}
