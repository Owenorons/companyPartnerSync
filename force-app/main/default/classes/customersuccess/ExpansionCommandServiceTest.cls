/*
 * Covers ExpansionCommandService: minor expansion stays within the
 * relationship when policy permits (no new deal), major expansion creates
 * a new Deal with correct provenance through the real, unmodified PDLM
 * registration pipeline, and expansion revenue is booked as
 * Revenue_Type__c = 'Expansion' once the outcome is real (minor completion,
 * or major completion gated on the resulting deal actually closing won).
 */
@IsTest
private class ExpansionCommandServiceTest {
  @IsTest
  static void minorExpansionStaysWithinTheRelationshipWhenPolicyPermits() {
    Fixture fixture = createFixture();
    ExpansionCommandService.testPolicyOverride = new Expansion_Policy__mdt(
      Requires_New_Deal__c = false,
      Minor_Expansion_Threshold_Percentage__c = 20
    );

    System.runAs(fixture.internalUser) {
      ExpansionCommand identifyCommand = new ExpansionCommand();
      identifyCommand.customerSuccessEngagementId = fixture.engagement.Id;
      identifyCommand.customerAccountId = fixture.customer.Id;
      identifyCommand.originatingDealId = fixture.deal.Id;
      identifyCommand.primaryPartnerId = fixture.partner.Id;
      identifyCommand.expansionType = 'Seat Increase';
      identifyCommand.description = 'Customer wants 10 more seats.';
      Partner_Expansion__c expansion = ExpansionCommandService.identify(
        identifyCommand
      );

      ExpansionCommand qualifyCommand = new ExpansionCommand();
      qualifyCommand.expansionId = expansion.Id;
      qualifyCommand.expectedVersion = 0;
      qualifyCommand.estimatedPercentageIncrease = 10;
      Partner_Expansion__c qualified = ExpansionCommandService.qualify(
        qualifyCommand
      );

      Assert.areEqual('Minor-Approved', qualified.Status__c);
      Assert.isNull(qualified.Resulting_Deal__c);
    }
  }

  @IsTest
  static void majorExpansionCreatesANewDealThroughTheRealPipeline() {
    Fixture fixture = createFixture();
    ExpansionCommandService.testPolicyOverride = new Expansion_Policy__mdt(
      Requires_New_Deal__c = true
    );

    Partner_Expansion__c withDeal;
    System.runAs(fixture.internalUser) {
      ExpansionCommand identifyCommand = new ExpansionCommand();
      identifyCommand.customerSuccessEngagementId = fixture.engagement.Id;
      identifyCommand.customerAccountId = fixture.customer.Id;
      identifyCommand.originatingDealId = fixture.deal.Id;
      identifyCommand.primaryPartnerId = fixture.partner.Id;
      identifyCommand.expansionType = 'Additional Product';
      identifyCommand.description = 'Customer wants a second product line.';
      Partner_Expansion__c expansion = ExpansionCommandService.identify(
        identifyCommand
      );

      ExpansionCommand qualifyCommand = new ExpansionCommand();
      qualifyCommand.expansionId = expansion.Id;
      qualifyCommand.expectedVersion = 0;
      Partner_Expansion__c qualified = ExpansionCommandService.qualify(
        qualifyCommand
      );
      Assert.areEqual('New Deal Required', qualified.Status__c);

      ExpansionCommand createDealCommand = new ExpansionCommand();
      createDealCommand.expansionId = expansion.Id;
      createDealCommand.expectedVersion = qualified.Version_Number__c.intValue();
      createDealCommand.businessProblem = 'Needs a second product line.';
      createDealCommand.proposedSolution = 'Add-on module.';
      createDealCommand.estimatedRevenue = 40000;
      createDealCommand.estimatedCloseDate = Date.today().addDays(60);
      withDeal = ExpansionCommandService.createExpansionDeal(createDealCommand);
    }

    Assert.areEqual('Deal Created', withDeal.Status__c);
    Assert.isNotNull(withDeal.Resulting_Deal__c);

    Deal_Registration__c resultingDeal = [
      SELECT Origin_Type__c, Parent_Deal__c, Originating_Customer_Success__c
      FROM Deal_Registration__c
      WHERE Id = :withDeal.Resulting_Deal__c
    ];
    Assert.areEqual('Expansion', resultingDeal.Origin_Type__c);
    Assert.areEqual(fixture.deal.Id, resultingDeal.Parent_Deal__c);
    Assert.areEqual(
      fixture.engagement.Id,
      resultingDeal.Originating_Customer_Success__c
    );
  }

  @IsTest
  static void completeBooksExpansionRevenueForAMinorExpansion() {
    Fixture fixture = createFixture();
    Partner_Expansion__c expansion = new Partner_Expansion__c(
      Customer_Success_Engagement__c = fixture.engagement.Id,
      Customer_Account__c = fixture.customer.Id,
      Originating_Deal__c = fixture.deal.Id,
      Primary_Partner__c = fixture.partner.Id,
      Expansion_Type__c = 'Usage Increase',
      Status__c = 'Minor-Approved',
      Version_Number__c = 0
    );
    insert expansion;
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Record_Manual_Revenue',
      true
    );

    System.runAs(fixture.internalUser) {
      ExpansionCommand completeCommand = new ExpansionCommand();
      completeCommand.expansionId = expansion.Id;
      completeCommand.expectedVersion = 0;
      completeCommand.completedAmount = 15000;
      Partner_Expansion__c completed = ExpansionCommandService.complete(
        completeCommand
      );
      Assert.areEqual('Completed', completed.Status__c);
    }

    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Deal_Revenue__c
        WHERE Deal__c = :fixture.deal.Id AND Revenue_Type__c = 'Expansion'
      ]
    );
  }

  @IsTest
  static void completeRejectsAMajorExpansionWhoseDealHasNotClosedWon() {
    Fixture fixture = createFixture();
    Deal_Registration__c resultingDeal = PartnerSyncTestDataFactory.deal(
      fixture.customer.Id,
      fixture.partner.Id,
      null,
      null
    );
    resultingDeal.Status__c = 'Approved';
    resultingDeal.Stage__c = 'Qualification';
    resultingDeal.Origin_Type__c = 'Expansion';
    insert resultingDeal;
    Partner_Expansion__c expansion = new Partner_Expansion__c(
      Customer_Success_Engagement__c = fixture.engagement.Id,
      Customer_Account__c = fixture.customer.Id,
      Originating_Deal__c = fixture.deal.Id,
      Primary_Partner__c = fixture.partner.Id,
      Expansion_Type__c = 'Additional Product',
      Status__c = 'Deal Created',
      Resulting_Deal__c = resultingDeal.Id,
      Version_Number__c = 0
    );
    insert expansion;

    System.runAs(fixture.internalUser) {
      ExpansionCommand completeCommand = new ExpansionCommand();
      completeCommand.expansionId = expansion.Id;
      completeCommand.expectedVersion = 0;

      try {
        ExpansionCommandService.complete(completeCommand);
        Assert.fail(
          'Expected completion of an expansion whose deal has not closed won to be rejected.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('closed won'));
      }
    }
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.internalUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      fixture.internalUser.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Manage_Expansion',
      true
    );
    fixture.partner = PartnerSyncTestDataFactory.partnerAccount(
      'Expansion Test Partner'
    );
    fixture.customer = PartnerSyncTestDataFactory.customerAccount(
      'Expansion Test Customer'
    );
    insert new List<Account>{ fixture.partner, fixture.customer };

    fixture.deal = PartnerSyncTestDataFactory.deal(
      fixture.customer.Id,
      fixture.partner.Id,
      null,
      null
    );
    fixture.deal.Status__c = 'Approved';
    insert fixture.deal;

    fixture.engagement = new Customer_Success_Engagement__c(
      Customer_Account__c = fixture.customer.Id,
      Originating_Deal__c = fixture.deal.Id,
      Primary_Partner__c = fixture.partner.Id,
      Status__c = 'Active',
      Health_Status__c = 'Healthy',
      Version_Number__c = 0
    );
    insert fixture.engagement;

    return fixture;
  }

  private class Fixture {
    User internalUser;
    Account partner;
    Account customer;
    Deal_Registration__c deal;
    Customer_Success_Engagement__c engagement;
  }
}
