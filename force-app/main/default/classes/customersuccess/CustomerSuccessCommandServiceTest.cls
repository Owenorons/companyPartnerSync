/*
 * Covers CustomerSuccessCommandService: createEngagement consumes a
 * completed implementation into a Pending Handoff engagement with a real
 * handoff snapshot and is idempotent on redelivery, acceptHandoff
 * transitions to Active, recordChurn requires a reason and category, and
 * reopenEngagement creates a distinct new engagement rather than
 * resurrecting the churned one in place.
 */
@IsTest
private class CustomerSuccessCommandServiceTest {
  @IsTest
  static void createEngagementBuildsAPendingHandoffEngagementWithSnapshot() {
    Fixture fixture = createFixture();

    Customer_Success_Engagement__c engagement = CustomerSuccessCommandService.createEngagement(
      fixture.deal.Id
    );

    Assert.areEqual('Pending Handoff', engagement.Status__c);
    Assert.areEqual(fixture.implementation.Id, engagement.Implementation__c);
    Assert.areEqual(fixture.customer.Id, engagement.Customer_Account__c);
    Assert.areEqual(fixture.partner.Id, engagement.Primary_Partner__c);
    Assert.isNotNull(
      [
        SELECT Handoff_Snapshot__c
        FROM Customer_Success_Engagement__c
        WHERE Id = :engagement.Id
      ]
      .Handoff_Snapshot__c
    );
  }

  @IsTest
  static void createEngagementIsIdempotentOnRedelivery() {
    Fixture fixture = createFixture();

    Customer_Success_Engagement__c first = CustomerSuccessCommandService.createEngagement(
      fixture.deal.Id
    );
    Customer_Success_Engagement__c second = CustomerSuccessCommandService.createEngagement(
      fixture.deal.Id
    );

    Assert.areEqual(first.Id, second.Id);
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Customer_Success_Engagement__c
        WHERE Originating_Deal__c = :fixture.deal.Id
      ]
    );
  }

  @IsTest
  static void acceptHandoffTransitionsToActive() {
    Fixture fixture = createFixture();
    Customer_Success_Engagement__c engagement = CustomerSuccessCommandService.createEngagement(
      fixture.deal.Id
    );
    User csUser = internalCsUser();

    Customer_Success_Engagement__c accepted;
    System.runAs(csUser) {
      CustomerSuccessCommand command = new CustomerSuccessCommand();
      command.engagementId = engagement.Id;
      command.expectedVersion = 0;
      accepted = CustomerSuccessCommandService.acceptHandoff(command);
    }

    Assert.areEqual('Active', accepted.Status__c);
  }

  @IsTest
  static void recordChurnRequiresReasonAndCategory() {
    Fixture fixture = createFixture();
    Customer_Success_Engagement__c engagement = CustomerSuccessCommandService.createEngagement(
      fixture.deal.Id
    );
    User csUser = internalCsUser();

    System.runAs(csUser) {
      CustomerSuccessCommand command = new CustomerSuccessCommand();
      command.engagementId = engagement.Id;
      command.expectedVersion = 0;

      try {
        CustomerSuccessCommandService.recordChurn(command);
        Assert.fail(
          'Expected churn without a reason and category to be rejected.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('category'));
      }
    }
  }

  @IsTest
  static void reopenEngagementCreatesADistinctNewEngagement() {
    Fixture fixture = createFixture();
    Customer_Success_Engagement__c engagement = CustomerSuccessCommandService.createEngagement(
      fixture.deal.Id
    );
    User csUser = internalCsUser();

    Customer_Success_Engagement__c churned;
    Customer_Success_Engagement__c reopened;
    System.runAs(csUser) {
      CustomerSuccessCommand churnCommand = new CustomerSuccessCommand();
      churnCommand.engagementId = engagement.Id;
      churnCommand.expectedVersion = 0;
      churnCommand.reason = 'Customer did not renew.';
      churnCommand.churnCategory = 'Non-Renewal';
      churned = CustomerSuccessCommandService.recordChurn(churnCommand);

      CustomerSuccessCommand reopenCommand = new CustomerSuccessCommand();
      reopenCommand.engagementId = churned.Id;
      reopenCommand.reason = 'Customer signed a new deal.';
      reopened = CustomerSuccessCommandService.reopenEngagement(reopenCommand);
    }

    Assert.areNotEqual(churned.Id, reopened.Id);
    Assert.areEqual('Active', reopened.Status__c);
    Assert.areEqual(churned.Id, reopened.Previous_Engagement__c);
    Assert.areEqual(
      'Churned',
      [
        SELECT Status__c
        FROM Customer_Success_Engagement__c
        WHERE Id = :churned.Id
      ]
      .Status__c,
      'Reopening must not mutate the churned engagement - it creates a new one.'
    );
  }

  // Concurrency pair: a second actor's acceptHandoff attempt, still
  // holding the pre-accept version, is rejected rather than silently
  // clobbering the acceptance that already committed.
  @IsTest
  static void secondConcurrentAcceptHandoffFailsOnStaleVersion() {
    Fixture fixture = createFixture();
    Customer_Success_Engagement__c engagement = CustomerSuccessCommandService.createEngagement(
      fixture.deal.Id
    );
    User csUser = internalCsUser();

    System.runAs(csUser) {
      CustomerSuccessCommand first = new CustomerSuccessCommand();
      first.engagementId = engagement.Id;
      first.expectedVersion = 0;
      CustomerSuccessCommandService.acceptHandoff(first);

      CustomerSuccessCommand second = new CustomerSuccessCommand();
      second.engagementId = engagement.Id;
      second.expectedVersion = 0;

      try {
        CustomerSuccessCommandService.acceptHandoff(second);
        Assert.fail(
          'Expected the second concurrent acceptHandoff to be rejected.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('changed'));
      }
    }

    Assert.areEqual(
      'Active',
      [
        SELECT Status__c
        FROM Customer_Success_Engagement__c
        WHERE Id = :engagement.Id
      ]
      .Status__c
    );
  }

  private static User internalCsUser() {
    User csUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      csUser.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Manage_Customer_Success',
      true
    );
    return csUser;
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.partner = PartnerSyncTestDataFactory.partnerAccount(
      'Customer Success Partner'
    );
    fixture.customer = PartnerSyncTestDataFactory.customerAccount(
      'Customer Success Customer'
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

    fixture.implementation = new Deal_Implementation__c(
      Deal__c = fixture.deal.Id,
      Opportunity__c = fixture.opportunity.Id,
      Customer_Account__c = fixture.customer.Id,
      Primary_Partner__c = fixture.partner.Id,
      Implementation_Type__c = 'Standard',
      Status__c = 'Completed',
      Health__c = 'Healthy',
      Actual_Start_Date__c = Date.today().addDays(-30),
      Actual_Completion_Date__c = Date.today(),
      Version_Number__c = 0
    );
    insert fixture.implementation;

    return fixture;
  }

  private class Fixture {
    Account partner;
    Account customer;
    Opportunity opportunity;
    Deal_Registration__c deal;
    Deal_Implementation__c implementation;
  }
}
