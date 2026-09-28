/*
 * Covers RevenueCommandService: manual import creates a Pending revenue
 * row, duplicate External_Revenue_Key__c import is idempotent, Opportunity
 * Closed Won import creates only a Booking-type row (never Recognised
 * Revenue - doc §41.13), ambiguous import creates a Revenue_Reconciliation__c
 * row instead of guessing, confirm/adjust/reverse transitions, and
 * reversal creates a compensating row without mutating the original.
 */
@IsTest
private class RevenueCommandServiceTest {
  @IsTest
  static void manualImportCreatesAPendingRevenueRecord() {
    Fixture fixture = createFixture();

    System.runAs(fixture.financeUser) {
      RevenueImportRequest request = manualRequest(fixture.deal.Id, 'key-1');

      RevenueOutcome outcome = RevenueCommandService.importRevenue(request);

      Assert.areEqual(RevenueOutcome.MATCHED, outcome.outcome);
      Assert.isNotNull(outcome.revenue.Id);
      Assert.areEqual('Pending', outcome.revenue.Status__c);
      Assert.areEqual('Booking', outcome.revenue.Revenue_Type__c);
    }
  }

  @IsTest
  static void duplicateExternalKeyImportIsIdempotent() {
    Fixture fixture = createFixture();

    System.runAs(fixture.financeUser) {
      RevenueImportRequest request = manualRequest(fixture.deal.Id, 'key-2');
      RevenueOutcome first = RevenueCommandService.importRevenue(request);

      RevenueOutcome second = RevenueCommandService.importRevenue(
        manualRequest(fixture.deal.Id, 'key-2')
      );

      Assert.areEqual(RevenueOutcome.DUPLICATE_IGNORED, second.outcome);
      Assert.areEqual(first.revenue.Id, second.revenue.Id);
      Assert.areEqual(
        1,
        [
          SELECT COUNT()
          FROM Deal_Revenue__c
          WHERE External_Revenue_Key__c = 'key-2'
        ]
      );
    }
  }

  @IsTest
  static void opportunityImportCreatesOnlyABookingRow() {
    Fixture fixture = createFixture();

    System.runAs(fixture.financeUser) {
      RevenueImportRequest request = new RevenueImportRequest();
      request.sourceType = 'Opportunity';
      request.opportunityId = fixture.opportunity.Id;

      RevenueOutcome outcome = RevenueCommandService.importRevenue(request);

      Assert.areEqual(RevenueOutcome.MATCHED, outcome.outcome);
      Assert.areEqual('Booking', outcome.revenue.Revenue_Type__c);
      Assert.areNotEqual('Recognised Revenue', outcome.revenue.Revenue_Type__c);
    }
  }

  @IsTest
  static void unmatchedOpportunityImportCreatesAReconciliationRow() {
    Fixture fixture = createFixture();
    Opportunity orphanOpportunity = PartnerSyncTestDataFactory.opportunity(
      fixture.customer.Id,
      fixture.partner.Id,
      null
    );
    orphanOpportunity.StageName = 'Closed Won';
    insert orphanOpportunity;

    System.runAs(fixture.financeUser) {
      RevenueImportRequest request = new RevenueImportRequest();
      request.sourceType = 'Opportunity';
      request.opportunityId = orphanOpportunity.Id;

      RevenueOutcome outcome = RevenueCommandService.importRevenue(request);

      Assert.areEqual(RevenueOutcome.RECONCILIATION_REQUIRED, outcome.outcome);
      Assert.isNotNull(outcome.reconciliation.Id);
      Assert.areEqual('Open', outcome.reconciliation.Status__c);
      Assert.isNull(
        [
          SELECT Deal__c
          FROM Deal_Revenue__c
          WHERE Id = :outcome.reconciliation.Revenue__c
        ]
        .Deal__c
      );
    }
  }

  @IsTest
  static void confirmAdjustAndReverseTransitions() {
    Fixture fixture = createFixture();

    Deal_Revenue__c revenue;
    System.runAs(fixture.financeUser) {
      revenue = RevenueCommandService.importRevenue(
          manualRequest(fixture.deal.Id, 'key-3')
        )
        .revenue;

      RevenueCommand confirm = new RevenueCommand();
      confirm.revenueId = revenue.Id;
      confirm.expectedVersion = 0;
      RevenueCommandService.confirmRevenue(confirm);

      RevenueCommand adjust = new RevenueCommand();
      adjust.revenueId = revenue.Id;
      adjust.expectedVersion = 1;
      adjust.reason = 'Correcting a data-entry error.';
      adjust.newGrossAmount = 75000;
      RevenueCommandService.adjustRevenue(adjust);

      RevenueCommand reverse = new RevenueCommand();
      reverse.revenueId = revenue.Id;
      reverse.expectedVersion = 2;
      reverse.reason = 'Deal fell through after booking.';
      Deal_Revenue__c compensating = RevenueCommandService.reverseRevenue(
        reverse
      );

      Assert.areEqual(revenue.Id, compensating.Reversal_Of__c);
      Assert.areEqual('Reversal', compensating.Revenue_Type__c);
      Assert.areEqual(-75000, compensating.Gross_Amount__c);
    }

    Deal_Revenue__c refreshed = [
      SELECT Status__c, Gross_Amount__c
      FROM Deal_Revenue__c
      WHERE Id = :revenue.Id
    ];
    Assert.areEqual('Reversed', refreshed.Status__c);
    Assert.areEqual(
      75000,
      refreshed.Gross_Amount__c,
      'Reversal must not mutate the original record - it stays at its adjusted amount.'
    );
  }

  // Doc §41.42's reversal orchestration: reversing revenue also reverses
  // its dependent attribution and cancels a dependent incentive that
  // hasn't been paid yet - neither is left silently pointing at revenue
  // that no longer exists.
  @IsTest
  static void reversingRevenueCascadesToAttributionAndUnpaidIncentive() {
    Fixture fixture = createFixture();

    Deal_Revenue__c revenue;
    Deal_Revenue_Attribution__c attribution;
    Partner_Incentive__c incentive;
    System.runAs(fixture.financeUser) {
      revenue = RevenueCommandService.importRevenue(
          manualRequest(fixture.deal.Id, 'key-cascade')
        )
        .revenue;

      RevenueCommand confirm = new RevenueCommand();
      confirm.revenueId = revenue.Id;
      confirm.expectedVersion = 0;
      RevenueCommandService.confirmRevenue(confirm);
    }

    attribution = new Deal_Revenue_Attribution__c(
      Revenue__c = revenue.Id,
      Deal__c = fixture.deal.Id,
      Partner_Account__c = fixture.partner.Id,
      Attribution_Type__c = 'Sourced',
      Attribution_Percentage__c = 100,
      Attributed_Amount__c = 100000,
      Status__c = 'Calculated',
      Version_Number__c = 0
    );
    insert attribution;
    incentive = new Partner_Incentive__c(
      Deal__c = fixture.deal.Id,
      Revenue__c = revenue.Id,
      Revenue_Attribution__c = attribution.Id,
      Partner_Account__c = fixture.partner.Id,
      Incentive_Type__c = 'Commission',
      Status__c = 'Eligible',
      Eligible_Base_Amount__c = 100000,
      Version_Number__c = 0
    );
    insert incentive;

    System.runAs(fixture.financeUser) {
      RevenueCommand reverse = new RevenueCommand();
      reverse.revenueId = revenue.Id;
      reverse.expectedVersion = 1;
      reverse.reason = 'Customer cancelled the order.';
      RevenueCommandService.reverseRevenue(reverse);
    }

    Assert.areEqual(
      'Reversed',
      [
        SELECT Status__c
        FROM Deal_Revenue_Attribution__c
        WHERE Id = :attribution.Id
      ]
      .Status__c
    );
    Assert.areEqual(
      'Cancelled',
      [SELECT Status__c FROM Partner_Incentive__c WHERE Id = :incentive.Id]
      .Status__c
    );
  }

  // Proves a real, honestly-scoped ceiling for manual imports called in a
  // loop within one transaction - importRevenue() does ~2 SOQL + 1 DML per
  // call (idempotency check + insert), so 40 stays safely under both the
  // 100-SOQL and 150-DML limits; no batch class in this codebase currently
  // calls importRevenue() in a loop at all (Known Adaptation #9 - no
  // RevenueReconciliationBatch), so this proves the command itself is
  // bulk-safe up to a real ceiling rather than claiming a false 200.
  @IsTest
  static void imports40RevenueRecordsWithinGovernorLimits() {
    Fixture fixture = createFixture();

    System.runAs(fixture.financeUser) {
      Test.startTest();
      for (Integer index = 0; index < 40; index++) {
        RevenueCommandService.importRevenue(
          manualRequest(fixture.deal.Id, 'bulk-key-' + index)
        );
      }
      Test.stopTest();
    }

    Assert.areEqual(
      40,
      [SELECT COUNT() FROM Deal_Revenue__c WHERE Deal__c = :fixture.deal.Id]
    );
  }

  private static RevenueImportRequest manualRequest(Id dealId, String key) {
    RevenueImportRequest request = new RevenueImportRequest();
    request.sourceType = 'Manual';
    request.explicitDealId = dealId;
    request.revenueType = 'Booking';
    request.grossAmount = 100000;
    request.netAmount = 100000;
    request.externalRevenueKey = key;
    request.revenueDate = Date.today();
    return request;
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.financeUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      fixture.financeUser.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Record_Manual_Revenue',
      true
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Reverse_Revenue',
      true
    );

    fixture.partner = PartnerSyncTestDataFactory.partnerAccount(
      'Revenue Partner'
    );
    fixture.customer = PartnerSyncTestDataFactory.customerAccount(
      'Revenue Customer'
    );
    insert new List<Account>{ fixture.partner, fixture.customer };

    fixture.opportunity = PartnerSyncTestDataFactory.opportunity(
      fixture.customer.Id,
      fixture.partner.Id,
      null
    );
    fixture.opportunity.StageName = 'Closed Won';
    insert fixture.opportunity;

    fixture.deal = PartnerSyncTestDataFactory.deal(
      fixture.customer.Id,
      fixture.partner.Id,
      null,
      fixture.opportunity.Id
    );
    fixture.deal.Status__c = 'Approved';
    insert fixture.deal;

    insert new Deal_Opportunity__c(
      Deal__c = fixture.deal.Id,
      Opportunity__c = fixture.opportunity.Id,
      Partner_Account__c = fixture.partner.Id,
      Relationship_Type__c = 'Primary',
      Primary__c = true,
      Current__c = true,
      Relationship_Key__c = fixture.deal.Id + '|' + fixture.opportunity.Id,
      Version_Number__c = 0
    );

    return fixture;
  }

  private class Fixture {
    User financeUser;
    Account partner;
    Account customer;
    Opportunity opportunity;
    Deal_Registration__c deal;
  }
}
