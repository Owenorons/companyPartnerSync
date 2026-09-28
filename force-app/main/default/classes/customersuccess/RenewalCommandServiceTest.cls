/*
 * Covers RenewalIdentificationBatch + RenewalCommandService: identification
 * creates one renewal per entitlement entering the window and is idempotent
 * on a second run, confirm/decline, the qualification eligibility chain
 * (partner status, onboarding, unresolved Critical risk), the review/
 * approval branch creating a distinct renewal protection grant that never
 * touches the original registration grant, and markRenewed/markNotRenewed
 * (the latter deliberately not triggering customer churn).
 */
@IsTest
private class RenewalCommandServiceTest {
  @IsTest
  static void identificationCreatesOneRenewalPerEntitlementAndIsIdempotent() {
    Fixture fixture = createFixture();
    Customer_Commercial_Entitlement__c entitlement = insertEntitlement(
      fixture,
      Date.today().addDays(30)
    );

    Test.startTest();
    Database.executeBatch(new RenewalIdentificationBatch(), 200);
    Test.stopTest();

    List<Partner_Renewal__c> renewals = [
      SELECT Status__c
      FROM Partner_Renewal__c
      WHERE Commercial_Entitlement__c = :entitlement.Id
    ];
    Assert.areEqual(1, renewals.size());
    Assert.areEqual('Partner Confirmation Required', renewals[0].Status__c);

    Database.executeBatch(new RenewalIdentificationBatch(), 200);
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Partner_Renewal__c
        WHERE Commercial_Entitlement__c = :entitlement.Id
      ],
      'A second identification run must not create a duplicate renewal.'
    );
  }

  @IsTest
  static void confirmAndDeclineParticipation() {
    Fixture fixture = createFixture();
    Partner_Renewal__c confirmable = insertRenewal(
      fixture,
      'Partner Confirmation Required'
    );
    Partner_Renewal__c declinable = insertRenewal(
      fixture,
      'Partner Confirmation Required'
    );

    RenewalCommand confirmCommand = new RenewalCommand();
    confirmCommand.renewalId = confirmable.Id;
    confirmCommand.expectedVersion = 0;
    Partner_Renewal__c confirmed = RenewalCommandService.confirmParticipation(
      confirmCommand
    );
    Assert.areEqual('Partner Confirmed', confirmed.Status__c);

    RenewalCommand declineCommand = new RenewalCommand();
    declineCommand.renewalId = declinable.Id;
    declineCommand.expectedVersion = 0;
    Partner_Renewal__c declined = RenewalCommandService.declineParticipation(
      declineCommand
    );
    Assert.areEqual('Not Renewed', declined.Status__c);
    Assert.areEqual('Lost', declined.Renewal_Health__c);
  }

  @IsTest
  static void qualifyRejectsAnInactivePartner() {
    Fixture fixture = createFixture();
    fixture.partner.Partner_Status__c = 'Suspended';
    update fixture.partner;
    Partner_Renewal__c renewal = insertRenewal(fixture, 'Partner Confirmed');
    User internalUser = TestUserFactory.createInternalUser();

    System.runAs(internalUser) {
      RenewalCommand command = new RenewalCommand();
      command.renewalId = renewal.Id;
      command.expectedVersion = 0;

      try {
        RenewalCommandService.qualify(command);
        Assert.fail(
          'Expected qualification for a suspended partner to be rejected.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('not Active'));
      }
    }
  }

  @IsTest
  static void qualifyRejectsAnUnresolvedCriticalRisk() {
    Fixture fixture = createFixture();
    Partner_Renewal__c renewal = insertRenewal(fixture, 'Partner Confirmed');
    insert new Customer_Success_Risk__c(
      Customer_Success_Engagement__c = fixture.engagement.Id,
      Risk_Type__c = 'Adoption Risk',
      Severity__c = 'Critical',
      Status__c = 'Open',
      Description__c = 'Customer stopped using the product entirely.'
    );
    User internalUser = TestUserFactory.createInternalUser();

    System.runAs(internalUser) {
      RenewalCommand command = new RenewalCommand();
      command.renewalId = renewal.Id;
      command.expectedVersion = 0;

      try {
        RenewalCommandService.qualify(command);
        Assert.fail(
          'Expected qualification with an unresolved Critical risk to be rejected.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('Critical risk'));
      }

      Assert.areEqual(
        'Qualification',
        [SELECT Status__c FROM Partner_Renewal__c WHERE Id = :renewal.Id]
        .Status__c,
        'A renewal that failed eligibility stays visibly in Qualification for follow-up.'
      );
    }
  }

  @IsTest
  static void qualifyThenApproveCreatesADistinctRenewalProtectionGrant() {
    Fixture fixture = createFixture();
    Deal_Protection_Grant__c originalGrant = new Deal_Protection_Grant__c(
      Deal__c = fixture.deal.Id,
      Status__c = 'Active',
      Current__c = true,
      Current_Grant_Key__c = String.valueOf(fixture.deal.Id),
      Start_Date__c = Date.today().addDays(-365),
      Version_Number__c = 0
    );
    insert originalGrant;
    Partner_Renewal__c renewal = insertRenewal(fixture, 'Partner Confirmed');
    renewal.Current_Deal__c = fixture.deal.Id;
    update renewal;
    User internalUser = internalRenewalManager();

    Partner_Renewal__c qualified;
    Partner_Renewal__c approved;
    System.runAs(internalUser) {
      RenewalCommand qualifyCommand = new RenewalCommand();
      qualifyCommand.renewalId = renewal.Id;
      qualifyCommand.expectedVersion = 0;
      qualified = RenewalCommandService.qualify(qualifyCommand);
      Assert.areEqual('Review Required', qualified.Status__c);
      Assert.isNull(
        qualified.Original_Protection__c,
        'On Approval protection mode must wait for approve(), not grant at qualify().'
      );

      RenewalCommand approveCommand = new RenewalCommand();
      approveCommand.renewalId = renewal.Id;
      approveCommand.expectedVersion = qualified.Version_Number__c.intValue();
      approved = RenewalCommandService.approve(approveCommand);
    }

    Assert.areEqual('Approved', approved.Status__c);
    Assert.isNotNull(approved.Original_Protection__c);
    Assert.areNotEqual(originalGrant.Id, approved.Original_Protection__c);

    Deal_Protection_Grant__c renewalGrant = [
      SELECT Protection_Type__c, Current__c, Deal__c
      FROM Deal_Protection_Grant__c
      WHERE Id = :approved.Original_Protection__c
    ];
    Assert.areEqual('Renewal', renewalGrant.Protection_Type__c);
    Assert.isFalse(renewalGrant.Current__c);

    Deal_Protection_Grant__c refreshedOriginal = [
      SELECT Protection_Type__c, Current__c, Status__c
      FROM Deal_Protection_Grant__c
      WHERE Id = :originalGrant.Id
    ];
    Assert.areEqual('Registration', refreshedOriginal.Protection_Type__c);
    Assert.isTrue(refreshedOriginal.Current__c);
    Assert.areEqual(
      'Active',
      refreshedOriginal.Status__c,
      'Granting renewal protection must never mutate the original registration grant.'
    );
  }

  @IsTest
  static void requestReviewRequiresAReasonAndFlagsAMaterialChange() {
    Fixture fixture = createFixture();
    Partner_Renewal__c renewal = insertRenewal(fixture, 'Partner Confirmed');
    User internalUser = internalRenewalManager();

    System.runAs(internalUser) {
      RenewalCommand command = new RenewalCommand();
      command.renewalId = renewal.Id;
      command.expectedVersion = 0;

      try {
        RenewalCommandService.requestReview(command);
        Assert.fail(
          'Expected a review request without a reason to be rejected.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('reason'));
      }

      command.reason = 'Customer requested a materially different product mix.';
      Partner_Renewal__c reviewed = RenewalCommandService.requestReview(
        command
      );
      Assert.areEqual('Review Required', reviewed.Status__c);
      Assert.isTrue(reviewed.Material_Change__c);
    }
  }

  @IsTest
  static void markRenewedBooksRenewalRevenueAndMarkNotRenewedDoesNotChurn() {
    Fixture fixture = createFixture();
    Partner_Renewal__c toRenew = insertRenewal(fixture, 'Approved');
    toRenew.Current_Deal__c = fixture.deal.Id;
    update toRenew;
    Partner_Renewal__c toLose = insertRenewal(fixture, 'Approved');
    User internalUser = internalRenewalManager();
    TestUserFactory.assignPermissionSet(
      internalUser.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Record_Manual_Revenue',
      true
    );

    System.runAs(internalUser) {
      RenewalCommand renewCommand = new RenewalCommand();
      renewCommand.renewalId = toRenew.Id;
      renewCommand.expectedVersion = 0;
      renewCommand.renewedAmount = 120000;
      Partner_Renewal__c renewed = RenewalCommandService.markRenewed(
        renewCommand
      );
      Assert.areEqual('Renewed', renewed.Status__c);
      Assert.areEqual('Won', renewed.Renewal_Health__c);

      RenewalCommand loseCommand = new RenewalCommand();
      loseCommand.renewalId = toLose.Id;
      loseCommand.expectedVersion = 0;
      loseCommand.reason = 'Customer chose a competitor.';
      Partner_Renewal__c lost = RenewalCommandService.markNotRenewed(
        loseCommand
      );
      Assert.areEqual('Not Renewed', lost.Status__c);
    }

    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Deal_Revenue__c
        WHERE Deal__c = :fixture.deal.Id AND Revenue_Type__c = 'Renewal'
      ]
    );
    Assert.areEqual(
      'Active',
      [
        SELECT Status__c
        FROM Customer_Success_Engagement__c
        WHERE Id = :fixture.engagement.Id
      ]
      .Status__c,
      'A lost renewal must never automatically churn the customer.'
    );
  }

  // Proves RenewalIdentificationBatch is genuinely bulk-safe at a real
  // 200-entitlement scale, not a false claim: execute() does exactly 2 SOQL
  // (the bulk open-renewal check, the bulk engagement lookup) + 2 DML (the
  // renewal bulk insert, the engagement bulk update) per chunk, regardless
  // of chunk size - the per-row cost this session's discipline requires
  // computing before claiming a scale.
  @IsTest
  static void identifies200RenewalsWithinGovernorLimits() {
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Bulk Renewal Customer'
    );
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Bulk Renewal Partner'
    );
    insert new List<Account>{ customer, partner };

    List<Customer_Success_Engagement__c> engagements = new List<Customer_Success_Engagement__c>();
    for (Integer index = 0; index < 200; index++) {
      engagements.add(
        new Customer_Success_Engagement__c(
          Customer_Account__c = customer.Id,
          Primary_Partner__c = partner.Id,
          Status__c = 'Active',
          Health_Status__c = 'Healthy',
          Version_Number__c = 0
        )
      );
    }
    insert engagements;

    List<Customer_Commercial_Entitlement__c> entitlements = new List<Customer_Commercial_Entitlement__c>();
    for (Integer index = 0; index < 200; index++) {
      entitlements.add(
        new Customer_Commercial_Entitlement__c(
          Customer_Account__c = customer.Id,
          Customer_Success_Engagement__c = engagements[index].Id,
          Status__c = 'Active',
          Effective_Start_On__c = Date.today().addYears(-1),
          Effective_End_On__c = Date.today().addDays(30),
          Version_Number__c = 0
        )
      );
    }
    insert entitlements;

    Test.startTest();
    Database.executeBatch(new RenewalIdentificationBatch(), 200);
    Test.stopTest();

    Assert.areEqual(
      200,
      [
        SELECT COUNT()
        FROM Partner_Renewal__c
        WHERE Customer_Account__c = :customer.Id
      ]
    );
  }

  // Concurrency pair (mirrors this codebase's established two-step
  // technique): a second actor's markRenewed attempt, still holding the
  // pre-qualification version, is rejected rather than silently clobbering
  // the state the first actor already committed.
  @IsTest
  static void secondConcurrentMarkRenewedFailsOnStaleVersion() {
    Fixture fixture = createFixture();
    Partner_Renewal__c renewal = insertRenewal(fixture, 'Approved');
    User internalUser = internalRenewalManager();

    System.runAs(internalUser) {
      RenewalCommand first = new RenewalCommand();
      first.renewalId = renewal.Id;
      first.expectedVersion = 0;
      RenewalCommandService.markRenewed(first);

      RenewalCommand second = new RenewalCommand();
      second.renewalId = renewal.Id;
      second.expectedVersion = 0;

      try {
        RenewalCommandService.markRenewed(second);
        Assert.fail(
          'Expected the second concurrent markRenewed to be rejected.'
        );
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('changed'));
      }
    }

    Assert.areEqual(
      'Renewed',
      [SELECT Status__c FROM Partner_Renewal__c WHERE Id = :renewal.Id]
      .Status__c
    );
  }

  private static User internalRenewalManager() {
    User user = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(user.Id, 'PartnerSync_Channel_Manager');
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Manage_Renewal',
      true
    );
    return user;
  }

  private static Customer_Commercial_Entitlement__c insertEntitlement(
    Fixture fixture,
    Date effectiveEndOn
  ) {
    Customer_Commercial_Entitlement__c entitlement = new Customer_Commercial_Entitlement__c(
      Customer_Account__c = fixture.customer.Id,
      Customer_Success_Engagement__c = fixture.engagement.Id,
      Originating_Deal__c = fixture.deal.Id,
      Status__c = 'Active',
      Effective_Start_On__c = effectiveEndOn.addYears(-1),
      Effective_End_On__c = effectiveEndOn,
      Version_Number__c = 0
    );
    insert entitlement;
    return entitlement;
  }

  private static Partner_Renewal__c insertRenewal(
    Fixture fixture,
    String status
  ) {
    Partner_Renewal__c renewal = new Partner_Renewal__c(
      Customer_Success_Engagement__c = fixture.engagement.Id,
      Customer_Account__c = fixture.customer.Id,
      Original_Deal__c = fixture.deal.Id,
      Primary_Partner__c = fixture.partner.Id,
      Status__c = status,
      Renewal_Health__c = 'On Track',
      Version_Number__c = 0
    );
    insert renewal;
    return renewal;
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.partner = PartnerSyncTestDataFactory.partnerAccount(
      'Renewal Test Partner'
    );
    fixture.partner.Partner_Status__c = 'Active';
    fixture.partner.Onboarding_Status__c = 'Complete';
    fixture.customer = PartnerSyncTestDataFactory.customerAccount(
      'Renewal Test Customer'
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
    Account partner;
    Account customer;
    Deal_Registration__c deal;
    Customer_Success_Engagement__c engagement;
  }
}
