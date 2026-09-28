/*
 * Covers CommercialEntitlementCommandService: record creates an Active
 * entitlement, renew closes the old one and creates a new version rather
 * than mutating dates in place, and cancel requires a reason.
 */
@IsTest
private class CommercialEntitlementCommandServiceTest {
  @IsTest
  static void recordCreatesAnActiveEntitlement() {
    Fixture fixture = createFixture();
    User internalUser = TestUserFactory.createInternalUser();

    Customer_Commercial_Entitlement__c entitlement;
    System.runAs(internalUser) {
      entitlement = CommercialEntitlementCommandService.record(
        recordCommand(fixture)
      );
    }

    Assert.areEqual('Active', entitlement.Status__c);
    Assert.areEqual(fixture.customer.Id, entitlement.Customer_Account__c);
  }

  @IsTest
  static void renewClosesTheOldEntitlementAndCreatesANewVersion() {
    Fixture fixture = createFixture();
    User internalUser = TestUserFactory.createInternalUser();

    Customer_Commercial_Entitlement__c original;
    Customer_Commercial_Entitlement__c renewed;
    System.runAs(internalUser) {
      original = CommercialEntitlementCommandService.record(
        recordCommand(fixture)
      );

      CommercialEntitlementCommand renewCommand = new CommercialEntitlementCommand();
      renewCommand.entitlementId = original.Id;
      renewCommand.expectedVersion = 0;
      renewCommand.effectiveStartOn = Date.today().addYears(1);
      renewCommand.effectiveEndOn = Date.today().addYears(2);
      renewed = CommercialEntitlementCommandService.renew(renewCommand);
    }

    Assert.areNotEqual(original.Id, renewed.Id);
    Assert.areEqual('Active', renewed.Status__c);
    Assert.areEqual(
      'Renewed',
      [
        SELECT Status__c
        FROM Customer_Commercial_Entitlement__c
        WHERE Id = :original.Id
      ]
      .Status__c,
      'Renewing must not mutate the original entitlement in place - it creates a new version.'
    );
  }

  @IsTest
  static void cancelRequiresAReason() {
    Fixture fixture = createFixture();
    User internalUser = TestUserFactory.createInternalUser();

    System.runAs(internalUser) {
      Customer_Commercial_Entitlement__c entitlement = CommercialEntitlementCommandService.record(
        recordCommand(fixture)
      );

      CommercialEntitlementCommand cancelCommand = new CommercialEntitlementCommand();
      cancelCommand.entitlementId = entitlement.Id;

      try {
        CommercialEntitlementCommandService.cancel(cancelCommand);
        Assert.fail('Expected a cancel without a reason to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('reason'));
      }
    }
  }

  private static CommercialEntitlementCommand recordCommand(Fixture fixture) {
    CommercialEntitlementCommand command = new CommercialEntitlementCommand();
    command.customerAccountId = fixture.customer.Id;
    command.product = 'PartnerSync Platform';
    command.productFamily = 'Platform';
    command.entitlementType = 'Subscription';
    command.effectiveStartOn = Date.today().addDays(-30);
    command.effectiveEndOn = Date.today().addDays(335);
    command.quantity = 100;
    return command;
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.customer = PartnerSyncTestDataFactory.customerAccount(
      'Entitlement Customer'
    );
    insert fixture.customer;
    return fixture;
  }

  private class Fixture {
    Account customer;
  }
}
