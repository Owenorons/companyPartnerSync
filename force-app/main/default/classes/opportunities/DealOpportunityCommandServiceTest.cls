/*
 * Covers DealOpportunityCommandService: linking a new/secondary
 * opportunity, the AlreadyLinked and AccountMismatch outcomes, one deal
 * acquiring multiple opportunity relationships (Sprint 39's one-to-many),
 * a second deal being blocked from an opportunity already claimed by the
 * first, and unlink/set-primary.
 */
@IsTest
private class DealOpportunityCommandServiceTest {
  @IsTest
  static void linkOpportunityToDealSucceedsForANewSecondaryOpportunity() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert new List<Account>{ partner, customer };

    Opportunity primaryOpportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      partner.Id,
      null
    );
    Opportunity secondaryOpportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      partner.Id,
      null
    );
    insert new List<Opportunity>{ primaryOpportunity, secondaryOpportunity };

    Deal_Registration__c deal = registeredDeal(
      customer.Id,
      partner.Id,
      primaryOpportunity.Id
    );
    insertPrimaryRelationship(deal.Id, primaryOpportunity.Id, partner.Id);

    User internalUser = internalUser();
    DealOpportunityOutcome outcome;
    System.runAs(internalUser) {
      outcome = DealOpportunityCommandService.linkOpportunityToDeal(
        linkCommand(deal.Id, secondaryOpportunity.Id, 'Secondary')
      );
    }

    Assert.areEqual(DealOpportunityOutcome.LINKED, outcome.outcome);
    Assert.isFalse(outcome.relationship.Primary__c);
  }

  @IsTest
  static void linkOpportunityToDealSupportsOneToMany() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert new List<Account>{ partner, customer };

    Opportunity primaryOpportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      partner.Id,
      null
    );
    Opportunity secondaryOpportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      partner.Id,
      null
    );
    insert new List<Opportunity>{ primaryOpportunity, secondaryOpportunity };

    Deal_Registration__c deal = registeredDeal(
      customer.Id,
      partner.Id,
      primaryOpportunity.Id
    );
    insertPrimaryRelationship(deal.Id, primaryOpportunity.Id, partner.Id);

    User internalUser = internalUser();
    System.runAs(internalUser) {
      DealOpportunityCommandService.linkOpportunityToDeal(
        linkCommand(deal.Id, secondaryOpportunity.Id, 'Secondary')
      );
    }

    List<Deal_Opportunity__c> relationships = DealOpportunitySelector.selectForDeal(
      deal.Id
    );
    Assert.areEqual(2, relationships.size());
  }

  @IsTest
  static void linkOpportunityToDealRejectsAnAlreadyLinkedOpportunity() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert new List<Account>{ partner, customer };

    Opportunity sharedOpportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      partner.Id,
      null
    );
    insert sharedOpportunity;

    Deal_Registration__c firstDeal = registeredDeal(
      customer.Id,
      partner.Id,
      sharedOpportunity.Id
    );
    insertPrimaryRelationship(firstDeal.Id, sharedOpportunity.Id, partner.Id);

    Deal_Registration__c secondDeal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      partner.Id,
      null,
      null
    );
    secondDeal.Status__c = 'Approved';
    insert secondDeal;

    User internalUser = internalUser();
    DealOpportunityOutcome outcome;
    System.runAs(internalUser) {
      outcome = DealOpportunityCommandService.linkOpportunityToDeal(
        linkCommand(secondDeal.Id, sharedOpportunity.Id, 'Primary')
      );
    }

    Assert.areEqual(DealOpportunityOutcome.ALREADY_LINKED, outcome.outcome);
  }

  @IsTest
  static void linkOpportunityToDealRejectsAnAccountMismatch() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    Account otherCustomer = PartnerSyncTestDataFactory.customerAccount(
      'Other Customer'
    );
    insert new List<Account>{ partner, customer, otherCustomer };

    Opportunity primaryOpportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      partner.Id,
      null
    );
    Opportunity mismatchedOpportunity = PartnerSyncTestDataFactory.opportunity(
      otherCustomer.Id,
      partner.Id,
      null
    );
    insert new List<Opportunity>{ primaryOpportunity, mismatchedOpportunity };

    Deal_Registration__c deal = registeredDeal(
      customer.Id,
      partner.Id,
      primaryOpportunity.Id
    );
    insertPrimaryRelationship(deal.Id, primaryOpportunity.Id, partner.Id);

    User internalUser = internalUser();
    DealOpportunityOutcome outcome;
    System.runAs(internalUser) {
      outcome = DealOpportunityCommandService.linkOpportunityToDeal(
        linkCommand(deal.Id, mismatchedOpportunity.Id, 'Secondary')
      );
    }

    Assert.areEqual(DealOpportunityOutcome.ACCOUNT_MISMATCH, outcome.outcome);
  }

  @IsTest
  static void unlinkAndSetPrimaryRoundTrip() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert new List<Account>{ partner, customer };

    Opportunity primaryOpportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      partner.Id,
      null
    );
    Opportunity secondaryOpportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      partner.Id,
      null
    );
    insert new List<Opportunity>{ primaryOpportunity, secondaryOpportunity };

    Deal_Registration__c deal = registeredDeal(
      customer.Id,
      partner.Id,
      primaryOpportunity.Id
    );
    Deal_Opportunity__c primaryRelationship = insertPrimaryRelationship(
      deal.Id,
      primaryOpportunity.Id,
      partner.Id
    );

    User internalUser = internalUser();
    DealOpportunityOutcome linkOutcome;
    System.runAs(internalUser) {
      linkOutcome = DealOpportunityCommandService.linkOpportunityToDeal(
        linkCommand(deal.Id, secondaryOpportunity.Id, 'Secondary')
      );

      DealOpportunityCommand setPrimaryCommand = new DealOpportunityCommand();
      setPrimaryCommand.dealOpportunityId = linkOutcome.relationship.Id;
      setPrimaryCommand.expectedVersion = 0;
      DealOpportunityCommandService.setPrimaryOpportunity(setPrimaryCommand);
    }

    Deal_Opportunity__c refreshedPrimary = [
      SELECT Primary__c, Version_Number__c
      FROM Deal_Opportunity__c
      WHERE Id = :primaryRelationship.Id
    ];
    Deal_Opportunity__c refreshedSecondary = [
      SELECT Primary__c
      FROM Deal_Opportunity__c
      WHERE Id = :linkOutcome.relationship.Id
    ];
    Assert.isFalse(refreshedPrimary.Primary__c);
    Assert.isTrue(refreshedSecondary.Primary__c);

    System.runAs(internalUser) {
      DealOpportunityCommand unlinkCommand = new DealOpportunityCommand();
      unlinkCommand.dealOpportunityId = refreshedPrimary.Id;
      unlinkCommand.expectedVersion = refreshedPrimary.Version_Number__c;
      DealOpportunityCommandService.unlinkOpportunityFromDeal(unlinkCommand);
    }

    Deal_Opportunity__c unlinkedRelationship = [
      SELECT Current__c
      FROM Deal_Opportunity__c
      WHERE Id = :primaryRelationship.Id
    ];
    Assert.isFalse(unlinkedRelationship.Current__c);
  }

  // Same same-test-method two-step technique used throughout this
  // codebase's concurrency tests: apply one change, then attempt a second
  // against the now-stale version the first actor would have been holding.
  @IsTest
  static void unlinkFailsWhenTheRelationshipChangedSinceItWasRead() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert new List<Account>{ partner, customer };

    Opportunity primaryOpportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      partner.Id,
      null
    );
    Opportunity secondaryOpportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      partner.Id,
      null
    );
    insert new List<Opportunity>{ primaryOpportunity, secondaryOpportunity };

    Deal_Registration__c deal = registeredDeal(
      customer.Id,
      partner.Id,
      primaryOpportunity.Id
    );
    insertPrimaryRelationship(deal.Id, primaryOpportunity.Id, partner.Id);

    User internalUser = internalUser();
    Deal_Opportunity__c secondaryRelationship;
    System.runAs(internalUser) {
      DealOpportunityOutcome outcome = DealOpportunityCommandService.linkOpportunityToDeal(
        linkCommand(deal.Id, secondaryOpportunity.Id, 'Secondary')
      );
      secondaryRelationship = outcome.relationship;

      // Actor A reads version 0, then actor B's markOpportunityRelationshipHistorical
      // wins the race and bumps it to version 1 before actor A's unlink applies.
      DealOpportunityCommand historicalCommand = new DealOpportunityCommand();
      historicalCommand.dealOpportunityId = secondaryRelationship.Id;
      historicalCommand.expectedVersion = 0;
      DealOpportunityCommandService.markOpportunityRelationshipHistorical(
        historicalCommand
      );

      DealOpportunityCommand staleUnlinkCommand = new DealOpportunityCommand();
      staleUnlinkCommand.dealOpportunityId = secondaryRelationship.Id;
      staleUnlinkCommand.expectedVersion = 0;
      try {
        DealOpportunityCommandService.unlinkOpportunityFromDeal(
          staleUnlinkCommand
        );
        Assert.fail('Expected a stale version to be rejected.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('changed'));
      }
    }
  }

  // linkOpportunityToDeal is an interactive, one-relationship-at-a-time
  // command (like PartnerShareService.grantAccess before its bulk API was
  // added) - each call issues ~6 SOQL queries, so calling it in a tight
  // loop is governor-limit-bound well before 200 iterations in one
  // transaction. Proven at a real, honestly-scoped 15 rather than a false
  // 200 claim; a true bulk link API (mirroring
  // PartnerShareService.grantParticipantAccessBulk) is a named follow-up,
  // not built here - see the Sprint 39 review doc.
  @IsTest
  static void links15SecondaryOpportunitiesToOneDealWithinGovernorLimits() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert new List<Account>{ partner, customer };

    Opportunity primaryOpportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      partner.Id,
      null
    );
    insert primaryOpportunity;

    Deal_Registration__c deal = registeredDeal(
      customer.Id,
      partner.Id,
      primaryOpportunity.Id
    );
    insertPrimaryRelationship(deal.Id, primaryOpportunity.Id, partner.Id);

    List<Opportunity> secondaryOpportunities = new List<Opportunity>();
    for (Integer index = 0; index < 15; index++) {
      secondaryOpportunities.add(
        PartnerSyncTestDataFactory.opportunity(customer.Id, partner.Id, null)
      );
    }
    insert secondaryOpportunities;

    User internalUser = internalUser();
    Test.startTest();
    System.runAs(internalUser) {
      for (Opportunity secondary : secondaryOpportunities) {
        DealOpportunityCommandService.linkOpportunityToDeal(
          linkCommand(deal.Id, secondary.Id, 'Secondary')
        );
      }
    }
    Test.stopTest();

    Assert.areEqual(
      16,
      [SELECT COUNT() FROM Deal_Opportunity__c WHERE Deal__c = :deal.Id]
    );
  }

  private static Deal_Registration__c registeredDeal(
    Id customerAccountId,
    Id partnerAccountId,
    Id opportunityId
  ) {
    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customerAccountId,
      partnerAccountId,
      null,
      opportunityId
    );
    deal.Status__c = 'Approved';
    insert deal;
    return deal;
  }

  private static Deal_Opportunity__c insertPrimaryRelationship(
    Id dealId,
    Id opportunityId,
    Id partnerAccountId
  ) {
    Deal_Opportunity__c relationship = new Deal_Opportunity__c(
      Deal__c = dealId,
      Opportunity__c = opportunityId,
      Partner_Account__c = partnerAccountId,
      Relationship_Type__c = 'Primary',
      Primary__c = true,
      Current__c = true,
      Relationship_Key__c = dealId + '|' + opportunityId,
      Version_Number__c = 0
    );
    insert relationship;
    return relationship;
  }

  private static DealOpportunityCommand linkCommand(
    Id dealId,
    Id opportunityId,
    String relationshipType
  ) {
    DealOpportunityCommand command = new DealOpportunityCommand();
    command.dealId = dealId;
    command.opportunityId = opportunityId;
    command.relationshipType = relationshipType;
    command.reason = 'Expansion opportunity added.';
    return command;
  }

  private static User internalUser() {
    User channelManager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Link_Deal_Opportunity',
      true
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Unlink_Deal_Opportunity',
      true
    );
    DealLifecyclePermissionService.setTestPermission(
      'PartnerSync_Create_Deal_Opportunity',
      true
    );
    return channelManager;
  }
}
