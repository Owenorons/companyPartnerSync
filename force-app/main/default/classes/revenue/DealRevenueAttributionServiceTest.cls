/*
 * Covers DealRevenueAttributionService: attribution calculated from
 * approved participant contributions, a contribution effective before the
 * revenue date still attributes even if its window has since closed (doc
 * §41.23 - historical attribution, not current state), the percentage cap
 * is enforced within one attribution dimension but not across dimensions,
 * and a protection-required policy blocks calculation when no active
 * grant exists.
 */
@IsTest
private class DealRevenueAttributionServiceTest {
  @IsTest
  static void calculatesAttributionFromApprovedContributions() {
    Fixture fixture = createFixture();
    insertContribution(
      fixture.dealParticipant.Id,
      'Origination',
      100,
      Date.today().addDays(-30),
      null
    );
    Deal_Revenue__c revenue = insertRevenue(fixture.deal.Id, Date.today());

    Test.startTest();
    List<Deal_Revenue_Attribution__c> rows = DealRevenueAttributionService.calculateAttribution(
      revenue.Id
    );
    Test.stopTest();

    Assert.areEqual(1, rows.size());
    Assert.areEqual('Sourced', rows[0].Attribution_Type__c);
    Assert.areEqual(100, rows[0].Attribution_Percentage__c);
    Assert.areEqual(50000, rows[0].Attributed_Amount__c);
  }

  @IsTest
  static void historicalContributionStillAttributesAfterItsWindowCloses() {
    Fixture fixture = createFixture();
    // The contribution's window closed months before "today", but the
    // revenue being attributed is effective *inside* that window - the
    // service must use the revenue's own date, not today's participant
    // state.
    insertContribution(
      fixture.dealParticipant.Id,
      'Origination',
      100,
      Date.newInstance(2025, 1, 1),
      Date.newInstance(2025, 6, 30)
    );
    Deal_Revenue__c revenue = insertRevenue(
      fixture.deal.Id,
      Date.newInstance(2025, 3, 15)
    );

    List<Deal_Revenue_Attribution__c> rows = DealRevenueAttributionService.calculateAttribution(
      revenue.Id
    );

    Assert.areEqual(1, rows.size());
    Assert.areEqual('Sourced', rows[0].Attribution_Type__c);
  }

  @IsTest
  static void percentageCapEnforcedWithinDimensionButNotAcrossDimensions() {
    Fixture fixture = createFixture();
    DealRevenueAttributionService.testPolicyOverride = new Revenue_Attribution_Policy__mdt(
      Policy_Key__c = 'Test',
      Policy_Version__c = '1',
      Maximum_Percentage__c = 60
    );
    insertContribution(
      fixture.dealParticipant.Id,
      'Origination',
      50,
      Date.today().addDays(-30),
      null
    );
    insertContribution(
      fixture.dealParticipant.Id,
      'Sales',
      50,
      Date.today().addDays(-30),
      null
    );
    Deal_Revenue__c revenue = insertRevenue(fixture.deal.Id, Date.today());

    // Two different dimensions (Sourced 50%, Influenced 50%), each under
    // the 60% cap individually - must succeed even though their sum is 100%.
    List<Deal_Revenue_Attribution__c> rows = DealRevenueAttributionService.calculateAttribution(
      revenue.Id
    );
    Assert.areEqual(2, rows.size());
  }

  @IsTest
  static void percentageCapRejectsWithinTheSameDimension() {
    Fixture fixture = createFixture();
    DealRevenueAttributionService.testPolicyOverride = new Revenue_Attribution_Policy__mdt(
      Policy_Key__c = 'Test',
      Policy_Version__c = '1',
      Maximum_Percentage__c = 60
    );
    insertContribution(
      fixture.dealParticipant.Id,
      'Origination',
      50,
      Date.today().addDays(-30),
      null
    );
    insertContribution(
      fixture.dealParticipant.Id,
      'Origination',
      60,
      Date.today().addDays(-30),
      null
    );
    Deal_Revenue__c revenue = insertRevenue(fixture.deal.Id, Date.today());

    try {
      DealRevenueAttributionService.calculateAttribution(revenue.Id);
      Assert.fail(
        'Expected the combined Sourced percentage to exceed the policy cap.'
      );
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('exceeds'));
    }
  }

  @IsTest
  static void protectionRequiredBlocksCalculationWithoutAnActiveGrant() {
    Fixture fixture = createFixture();
    DealRevenueAttributionService.testPolicyOverride = new Revenue_Attribution_Policy__mdt(
      Policy_Key__c = 'Test',
      Policy_Version__c = '1',
      Require_Protection__c = true,
      Maximum_Percentage__c = 100
    );
    insertContribution(
      fixture.dealParticipant.Id,
      'Origination',
      100,
      Date.today().addDays(-30),
      null
    );
    Deal_Revenue__c revenue = insertRevenue(fixture.deal.Id, Date.today());

    try {
      DealRevenueAttributionService.calculateAttribution(revenue.Id);
      Assert.fail(
        'Expected calculation to be blocked without an active protection grant.'
      );
    } catch (PartnerSyncHandledException expected) {
      Assert.isTrue(expected.getMessage().contains('protection'));
    }
  }

  // Proves a real, honestly-scoped ceiling for calling
  // calculateAttribution() in a loop across many different revenues in
  // one transaction - each call costs ~3 SOQL (revenue, protection check,
  // contributions) regardless of how many contribution rows it processes
  // (those are already bulk-fetched/bulk-inserted within one call), so 30
  // stays safely under the 100-SOQL limit.
  @IsTest
  static void calculatesAttributionFor30RevenuesWithinGovernorLimits() {
    Fixture fixture = createFixture();
    insertContribution(
      fixture.dealParticipant.Id,
      'Origination',
      100,
      Date.today().addDays(-30),
      null
    );

    List<Deal_Revenue__c> revenues = new List<Deal_Revenue__c>();
    for (Integer index = 0; index < 30; index++) {
      revenues.add(
        new Deal_Revenue__c(
          Deal__c = fixture.deal.Id,
          Revenue_Type__c = 'Booking',
          Source_Type__c = 'Manual',
          Status__c = 'Confirmed',
          Net_Amount__c = 1000,
          Revenue_Date__c = Date.today(),
          Version_Number__c = 0
        )
      );
    }
    insert revenues;

    Test.startTest();
    Integer totalRows = 0;
    for (Deal_Revenue__c revenue : revenues) {
      totalRows += DealRevenueAttributionService.calculateAttribution(
          revenue.Id
        )
        .size();
    }
    Test.stopTest();

    Assert.areEqual(30, totalRows);
  }

  private static Deal_Participant_Contribution__c insertContribution(
    Id dealParticipantId,
    String contributionType,
    Decimal percentage,
    Date effectiveFrom,
    Date effectiveTo
  ) {
    Deal_Participant_Contribution__c contribution = new Deal_Participant_Contribution__c(
      Deal_Participant__c = dealParticipantId,
      Contribution_Type__c = contributionType,
      Percentage__c = percentage,
      Effective_From__c = effectiveFrom,
      Effective_To__c = effectiveTo,
      Approved__c = true
    );
    insert contribution;
    return contribution;
  }

  private static Deal_Revenue__c insertRevenue(Id dealId, Date revenueDate) {
    Deal_Revenue__c revenue = new Deal_Revenue__c(
      Deal__c = dealId,
      Revenue_Type__c = 'Booking',
      Source_Type__c = 'Manual',
      Status__c = 'Confirmed',
      Net_Amount__c = 50000,
      Gross_Amount__c = 50000,
      Revenue_Date__c = revenueDate,
      Version_Number__c = 0
    );
    insert revenue;
    return revenue;
  }

  private static Deal_Participant__c insertParticipant(
    Id dealId,
    Id partnerAccountId
  ) {
    Deal_Participant__c participant = new Deal_Participant__c(
      Deal__c = dealId,
      Partner_Account__c = partnerAccountId,
      Participant_Type__c = 'Co-Sell Partner',
      Participant_Role__c = 'Co-Sell Contributor',
      Status__c = 'Active',
      Active_Participant_Key__c = dealId +
        '|Co-Sell Partner|' +
        partnerAccountId +
        '|Co-Sell Contributor|' +
        Math.round(Math.random() * 1000000),
      Version_Number__c = 0
    );
    insert participant;
    return participant;
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.partner = PartnerSyncTestDataFactory.partnerAccount(
      'Attribution Partner'
    );
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Attribution Customer'
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

    fixture.dealParticipant = insertParticipant(
      fixture.deal.Id,
      fixture.partner.Id
    );

    return fixture;
  }

  private class Fixture {
    Account partner;
    Deal_Registration__c deal;
    Deal_Participant__c dealParticipant;
  }
}
