/*
 * Covers RevenueAttributionCommandService: overrideAttribution requires a
 * reason and the restricted permission, preserves the calculation
 * snapshot, and a second concurrent override attempt using a stale
 * version is rejected (doc §41.63's concurrency pair); reverseAttribution
 * transitions to Reversed.
 */
@IsTest
private class RevenueAttributionCommandServiceTest {
  @IsTest
  static void overrideRequiresAReason() {
    Fixture fixture = createFixture();
    User approver = internalApprover();

    System.runAs(approver) {
      RevenueAttributionCommand command = new RevenueAttributionCommand();
      command.attributionId = fixture.attribution.Id;
      command.expectedVersion = 0;

      try {
        RevenueAttributionCommandService.overrideAttribution(command);
        Assert.fail('Expected an override without a reason to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('reason'));
      }
    }
  }

  @IsTest
  static void overrideRequiresTheRestrictedPermission() {
    Fixture fixture = createFixture();
    User unauthorizedUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      unauthorizedUser.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(unauthorizedUser) {
      RevenueAttributionCommand command = new RevenueAttributionCommand();
      command.attributionId = fixture.attribution.Id;
      command.expectedVersion = 0;
      command.reason = 'Partner disputed the calculated split.';

      try {
        RevenueAttributionCommandService.overrideAttribution(command);
        Assert.fail('Expected an unauthorized user to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('authority'));
      }
    }
  }

  @IsTest
  static void overridePreservesTheCalculatedSnapshot() {
    Fixture fixture = createFixture();
    String originalSnapshot = fixture.attribution.Calculation_Snapshot__c;
    User approver = internalApprover();

    System.runAs(approver) {
      RevenueAttributionCommand command = new RevenueAttributionCommand();
      command.attributionId = fixture.attribution.Id;
      command.expectedVersion = 0;
      command.reason = 'Partner disputed the calculated split.';
      command.newAttributionPercentage = 80;
      RevenueAttributionCommandService.overrideAttribution(command);
    }

    Deal_Revenue_Attribution__c refreshed = [
      SELECT
        Status__c,
        Override__c,
        Attribution_Percentage__c,
        Calculation_Snapshot__c
      FROM Deal_Revenue_Attribution__c
      WHERE Id = :fixture.attribution.Id
    ];
    Assert.areEqual('Overridden', refreshed.Status__c);
    Assert.isTrue(refreshed.Override__c);
    Assert.areEqual(80, refreshed.Attribution_Percentage__c);
    Assert.areEqual(originalSnapshot, refreshed.Calculation_Snapshot__c);
  }

  // Concurrency pair (doc §41.63): a second actor's override attempt,
  // still holding the pre-override version, is rejected rather than
  // silently clobbering the override that already committed.
  @IsTest
  static void secondConcurrentOverrideFailsOnStaleVersion() {
    Fixture fixture = createFixture();
    User approver = internalApprover();

    System.runAs(approver) {
      RevenueAttributionCommand first = new RevenueAttributionCommand();
      first.attributionId = fixture.attribution.Id;
      first.expectedVersion = 0;
      first.reason = 'Partner disputed the calculated split.';
      first.newAttributionPercentage = 80;
      RevenueAttributionCommandService.overrideAttribution(first);

      RevenueAttributionCommand second = new RevenueAttributionCommand();
      second.attributionId = fixture.attribution.Id;
      second.expectedVersion = 0;
      second.reason = 'A different reviewer, unaware of the first override.';
      second.newAttributionPercentage = 60;

      try {
        RevenueAttributionCommandService.overrideAttribution(second);
        Assert.fail('Expected the second concurrent override to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('changed'));
      }
    }

    Assert.areEqual(
      80,
      [
        SELECT Attribution_Percentage__c
        FROM Deal_Revenue_Attribution__c
        WHERE Id = :fixture.attribution.Id
      ]
      .Attribution_Percentage__c
    );
  }

  @IsTest
  static void reverseTransitionsToReversed() {
    Fixture fixture = createFixture();
    User approver = internalApprover();

    System.runAs(approver) {
      RevenueAttributionCommand command = new RevenueAttributionCommand();
      command.attributionId = fixture.attribution.Id;
      command.expectedVersion = 0;
      RevenueAttributionCommandService.reverseAttribution(command);
    }

    Assert.areEqual(
      'Reversed',
      [
        SELECT Status__c
        FROM Deal_Revenue_Attribution__c
        WHERE Id = :fixture.attribution.Id
      ]
      .Status__c
    );
  }

  private static User internalApprover() {
    User approver = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      approver.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Override_Revenue_Attribution',
      true
    );
    return approver;
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Attribution Command Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Attribution Command Customer'
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

    Deal_Revenue__c revenue = new Deal_Revenue__c(
      Deal__c = deal.Id,
      Revenue_Type__c = 'Booking',
      Source_Type__c = 'Manual',
      Status__c = 'Confirmed',
      Net_Amount__c = 50000,
      Version_Number__c = 0
    );
    insert revenue;

    fixture.attribution = new Deal_Revenue_Attribution__c(
      Revenue__c = revenue.Id,
      Deal__c = deal.Id,
      Partner_Account__c = partner.Id,
      Attribution_Type__c = 'Sourced',
      Attribution_Percentage__c = 100,
      Attributed_Amount__c = 50000,
      Status__c = 'Calculated',
      Calculation_Snapshot__c = '{"original":true}',
      Version_Number__c = 0
    );
    insert fixture.attribution;

    return fixture;
  }

  private class Fixture {
    Deal_Revenue_Attribution__c attribution;
  }
}
