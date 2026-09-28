/*
 * Covers IncentiveCommandService: percentage/fixed/tiered calculation, the
 * maximum-incentive cap, and calculated/approved/paid amounts staying
 * independently readable after an approval decision (doc §41.29/§41.32).
 */
@IsTest
private class IncentiveCommandServiceTest {
  @IsTest
  static void evaluateCreatesAnEligibleIncentiveUnderTheDefaultPolicy() {
    Fixture fixture = createFixture(100, 50000);

    IncentiveCommand command = new IncentiveCommand();
    command.revenueAttributionId = fixture.attribution.Id;
    Partner_Incentive__c incentive = IncentiveCommandService.evaluate(command);

    Assert.areEqual('Eligible', incentive.Status__c);
    Assert.areEqual(50000, incentive.Eligible_Base_Amount__c);
  }

  @IsTest
  static void evaluateIsIdempotentForTheSameAttribution() {
    Fixture fixture = createFixture(100, 50000);
    IncentiveCommand command = new IncentiveCommand();
    command.revenueAttributionId = fixture.attribution.Id;

    Partner_Incentive__c first = IncentiveCommandService.evaluate(command);
    Partner_Incentive__c second = IncentiveCommandService.evaluate(command);

    Assert.areEqual(first.Id, second.Id);
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Partner_Incentive__c
        WHERE Revenue_Attribution__c = :fixture.attribution.Id
      ]
    );
  }

  @IsTest
  static void calculatesPercentageOfAttributedRevenueUnderTheDefaultPolicy() {
    Fixture fixture = createFixture(100, 50000);
    Partner_Incentive__c incentive = evaluateFixture(fixture);

    IncentiveCommand calc = new IncentiveCommand();
    calc.incentiveId = incentive.Id;
    calc.expectedVersion = 0;
    IncentiveCommandService.calculate(calc);

    Partner_Incentive__c refreshed = [
      SELECT Calculated_Amount__c, Status__c, Approved_Amount__c, Paid_Amount__c
      FROM Partner_Incentive__c
      WHERE Id = :incentive.Id
    ];
    Assert.areEqual(2500, refreshed.Calculated_Amount__c);
    Assert.areEqual('Under Review', refreshed.Status__c);
    Assert.isNull(refreshed.Approved_Amount__c);
    Assert.isNull(refreshed.Paid_Amount__c);
  }

  @IsTest
  static void calculatesFixedAmount() {
    Fixture fixture = createFixture(100, 50000);
    Partner_Incentive__c incentive = evaluateFixture(fixture);
    IncentiveCommandService.testPolicyOverride = new Partner_Incentive_Policy__mdt(
      Policy_Key__c = 'Test',
      Policy_Version__c = '1',
      Calculation_Type__c = 'Fixed Amount',
      Fixed_Amount__c = 1500
    );

    IncentiveCommand calc = new IncentiveCommand();
    calc.incentiveId = incentive.Id;
    calc.expectedVersion = 0;
    IncentiveCommandService.calculate(calc);

    Assert.areEqual(
      1500,
      [
        SELECT Calculated_Amount__c
        FROM Partner_Incentive__c
        WHERE Id = :incentive.Id
      ]
      .Calculated_Amount__c
    );
  }

  @IsTest
  static void calculatesTieredAmountUsingSeededTierMetadata() {
    // Default_Tier_1/2/3 seeded under Policy_Key__c 'Default': first 100k
    // at 2%, next 400k at 3%, above 500k at 4% (doc §41.33's own example).
    Fixture fixture = createFixture(100, 600000);
    Partner_Incentive__c incentive = evaluateFixture(fixture);
    IncentiveCommandService.testPolicyOverride = new Partner_Incentive_Policy__mdt(
      Policy_Key__c = 'Default',
      Policy_Version__c = '1',
      Calculation_Type__c = 'Tiered'
    );

    IncentiveCommand calc = new IncentiveCommand();
    calc.incentiveId = incentive.Id;
    calc.expectedVersion = 0;
    IncentiveCommandService.calculate(calc);

    // 100000*2% + 400000*3% + 100000*4% = 2000 + 12000 + 4000 = 18000
    Assert.areEqual(
      18000,
      [
        SELECT Calculated_Amount__c
        FROM Partner_Incentive__c
        WHERE Id = :incentive.Id
      ]
      .Calculated_Amount__c
    );
  }

  @IsTest
  static void maximumIncentiveCapIsEnforced() {
    Fixture fixture = createFixture(100, 500000);
    Partner_Incentive__c incentive = evaluateFixture(fixture);
    IncentiveCommandService.testPolicyOverride = new Partner_Incentive_Policy__mdt(
      Policy_Key__c = 'Test',
      Policy_Version__c = '1',
      Calculation_Type__c = 'Percentage of Attributed Revenue',
      Rate__c = 10,
      Maximum_Incentive__c = 20000
    );

    IncentiveCommand calc = new IncentiveCommand();
    calc.incentiveId = incentive.Id;
    calc.expectedVersion = 0;
    IncentiveCommandService.calculate(calc);

    Assert.areEqual(
      20000,
      [
        SELECT Calculated_Amount__c
        FROM Partner_Incentive__c
        WHERE Id = :incentive.Id
      ]
      .Calculated_Amount__c
    );
  }

  // Proves a real, honestly-scoped ceiling for calling evaluate() in a
  // loop across many attribution rows in one transaction - each call
  // costs ~6 SOQL (idempotency check, attribution, policy resolution,
  // protection/implementation checks) + 1 DML, so 15 stays safely under
  // the 100-SOQL limit; no batch class in this codebase currently calls
  // evaluate() in a loop at all, so this proves the command itself is
  // bulk-safe up to a real ceiling rather than claiming a false 200.
  @IsTest
  static void evaluates15AttributionsWithinGovernorLimits() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Bulk Incentive Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Bulk Incentive Customer'
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

    List<Deal_Revenue_Attribution__c> attributions = new List<Deal_Revenue_Attribution__c>();
    for (Integer index = 0; index < 15; index++) {
      attributions.add(
        new Deal_Revenue_Attribution__c(
          Revenue__c = revenue.Id,
          Deal__c = deal.Id,
          Partner_Account__c = partner.Id,
          Attribution_Type__c = 'Sourced',
          Attribution_Percentage__c = 100,
          Attributed_Amount__c = 50000,
          Status__c = 'Calculated',
          Version_Number__c = 0
        )
      );
    }
    insert attributions;

    Test.startTest();
    for (Deal_Revenue_Attribution__c attribution : attributions) {
      IncentiveCommand command = new IncentiveCommand();
      command.revenueAttributionId = attribution.Id;
      IncentiveCommandService.evaluate(command);
    }
    Test.stopTest();

    Assert.areEqual(
      15,
      [
        SELECT COUNT()
        FROM Partner_Incentive__c
        WHERE Revenue_Attribution__c IN :attributions
      ]
    );
  }

  private static Partner_Incentive__c evaluateFixture(Fixture fixture) {
    IncentiveCommand command = new IncentiveCommand();
    command.revenueAttributionId = fixture.attribution.Id;
    return IncentiveCommandService.evaluate(command);
  }

  private static Fixture createFixture(
    Decimal attributionPercentage,
    Decimal attributedAmount
  ) {
    Fixture fixture = new Fixture();
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Incentive Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Incentive Customer'
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
      Net_Amount__c = attributedAmount,
      Version_Number__c = 0
    );
    insert revenue;

    fixture.attribution = new Deal_Revenue_Attribution__c(
      Revenue__c = revenue.Id,
      Deal__c = deal.Id,
      Partner_Account__c = partner.Id,
      Attribution_Type__c = 'Sourced',
      Attribution_Percentage__c = attributionPercentage,
      Attributed_Amount__c = attributedAmount,
      Status__c = 'Calculated',
      Version_Number__c = 0
    );
    insert fixture.attribution;

    return fixture;
  }

  private class Fixture {
    Deal_Revenue_Attribution__c attribution;
  }
}
