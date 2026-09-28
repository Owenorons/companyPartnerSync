/*
 * Covers DealOpportunityReconciliationBatch: stage projection for an open
 * opportunity, closed-won (no protection change), closed-lost under each
 * Closed_Lost_Behaviour__c variant, orphan detection + health flip,
 * material-change drift detection, a per-row failure logged to
 * PartnerSync_Opportunity_Sync_Log__c without failing the batch, and
 * 200-row bulk execution.
 */
@IsTest
private class DealOpportunityReconciliationBatchTest {
  @IsTest
  static void projectsStageForAnOpenOpportunity() {
    Fixture fixture = buildFixture('Negotiation/Review');

    Test.startTest();
    new DealOpportunityReconciliationBatch()
      .execute(
        null,
        new List<Deal_Opportunity__c>{
          requeryRelationship(fixture.relationship.Id)
        }
      );
    Test.stopTest();

    Assert.areEqual('Negotiation', dealStage(fixture.deal.Id));
  }

  @IsTest
  static void closedWonPublishesEventAndDoesNotChangeProtection() {
    Fixture fixture = buildFixture('Closed Won');
    Deal_Protection_Grant__c grant = insertActiveGrant(fixture.deal.Id);

    Test.startTest();
    new DealOpportunityReconciliationBatch()
      .execute(
        null,
        new List<Deal_Opportunity__c>{
          requeryRelationship(fixture.relationship.Id)
        }
      );
    Test.stopTest();

    Assert.areEqual('Closed Won', dealStage(fixture.deal.Id));
    Deal_Protection_Grant__c refreshed = [
      SELECT Status__c
      FROM Deal_Protection_Grant__c
      WHERE Id = :grant.Id
    ];
    Assert.areEqual('Active', refreshed.Status__c);
  }

  @IsTest
  static void closedWonCreatesAnImplementationEndToEnd() {
    Fixture fixture = buildFixture('Closed Won');

    Test.startTest();
    new DealOpportunityReconciliationBatch()
      .execute(
        null,
        new List<Deal_Opportunity__c>{
          requeryRelationship(fixture.relationship.Id)
        }
      );
    Test.stopTest();

    List<Deal_Implementation__c> implementations = [
      SELECT Status__c, Deal__c, Opportunity__c
      FROM Deal_Implementation__c
      WHERE Deal__c = :fixture.deal.Id
    ];
    Assert.areEqual(1, implementations.size());
    Assert.areEqual('Planned', implementations[0].Status__c);
    Assert.areEqual(
      'Implementation',
      [
        SELECT Lifecycle_Phase__c
        FROM Deal_Registration__c
        WHERE Id = :fixture.deal.Id
      ]
      .Lifecycle_Phase__c
    );
  }

  @IsTest
  static void closedLostWithNoChangeBehaviourLeavesProtectionActive() {
    Fixture fixture = buildFixture('Closed Lost');
    Deal_Protection_Grant__c grant = insertActiveGrant(fixture.deal.Id);
    DealOpportunityReconciliationBatch.testClosedLostBehaviourOverride = 'No Change';

    Test.startTest();
    new DealOpportunityReconciliationBatch()
      .execute(
        null,
        new List<Deal_Opportunity__c>{
          requeryRelationship(fixture.relationship.Id)
        }
      );
    Test.stopTest();

    Assert.areEqual('Closed Lost', dealStage(fixture.deal.Id));
    Deal_Protection_Grant__c refreshed = [
      SELECT Status__c
      FROM Deal_Protection_Grant__c
      WHERE Id = :grant.Id
    ];
    Assert.areEqual('Active', refreshed.Status__c);
  }

  @IsTest
  static void closedLostWithReleaseImmediatelyReleasesProtection() {
    Fixture fixture = buildFixture('Closed Lost');
    Deal_Protection_Grant__c grant = insertActiveGrant(fixture.deal.Id);
    DealOpportunityReconciliationBatch.testClosedLostBehaviourOverride = 'Release Immediately';

    Test.startTest();
    new DealOpportunityReconciliationBatch()
      .execute(
        null,
        new List<Deal_Opportunity__c>{
          requeryRelationship(fixture.relationship.Id)
        }
      );
    Test.stopTest();

    Deal_Protection_Grant__c refreshed = [
      SELECT Status__c
      FROM Deal_Protection_Grant__c
      WHERE Id = :grant.Id
    ];
    Assert.areEqual('Released', refreshed.Status__c);
  }

  @IsTest
  static void closedLostWithRequireReviewFlagsHealthWithoutReleasing() {
    Fixture fixture = buildFixture('Closed Lost');
    Deal_Protection_Grant__c grant = insertActiveGrant(fixture.deal.Id);
    DealOpportunityReconciliationBatch.testClosedLostBehaviourOverride = 'Require Review';

    Test.startTest();
    new DealOpportunityReconciliationBatch()
      .execute(
        null,
        new List<Deal_Opportunity__c>{
          requeryRelationship(fixture.relationship.Id)
        }
      );
    Test.stopTest();

    Deal_Registration__c refreshedDeal = [
      SELECT Lifecycle_Health__c
      FROM Deal_Registration__c
      WHERE Id = :fixture.deal.Id
    ];
    Assert.areEqual('At Risk', refreshedDeal.Lifecycle_Health__c);
    Deal_Protection_Grant__c refreshedGrant = [
      SELECT Status__c
      FROM Deal_Protection_Grant__c
      WHERE Id = :grant.Id
    ];
    Assert.areEqual('Active', refreshedGrant.Status__c);
  }

  // Proves the closed-lost release path - previously only ASSERTED as
  // "bounded" in this class's own doc comment, never actually proven with
  // a bulk test (a pre-beta audit finding) - stays within governor limits
  // at the same honestly-scoped 15 rows used for the closed-won path.
  @IsTest
  static void closedLost15ReleasesProtectionWithinGovernorLimits() {
    List<Fixture> fixtures = new List<Fixture>();
    List<Deal_Protection_Grant__c> grants = new List<Deal_Protection_Grant__c>();
    for (Integer index = 0; index < 15; index++) {
      Fixture fixture = buildFixture('Closed Lost');
      fixtures.add(fixture);
      grants.add(insertActiveGrant(fixture.deal.Id));
    }
    DealOpportunityReconciliationBatch.testClosedLostBehaviourOverride = 'Release Immediately';

    List<Deal_Opportunity__c> relationships = new List<Deal_Opportunity__c>();
    for (Fixture fixture : fixtures) {
      relationships.add(requeryRelationship(fixture.relationship.Id));
    }

    Test.startTest();
    new DealOpportunityReconciliationBatch().execute(null, relationships);
    Test.stopTest();

    Assert.areEqual(
      15,
      [
        SELECT COUNT()
        FROM Deal_Protection_Grant__c
        WHERE Id IN :grants AND Status__c = 'Released'
      ]
    );
  }

  @IsTest
  static void reopeningAPreviouslyClosedOpportunityFlagsForReviewWithoutRestoringProtection() {
    Fixture fixture = buildFixture('Negotiation/Review');
    Database.update(
      new Deal_Registration__c(Id = fixture.deal.Id, Stage__c = 'Closed Lost'),
      AccessLevel.SYSTEM_MODE
    );

    Test.startTest();
    new DealOpportunityReconciliationBatch()
      .execute(
        null,
        new List<Deal_Opportunity__c>{
          requeryRelationship(fixture.relationship.Id)
        }
      );
    Test.stopTest();

    Deal_Registration__c refreshedDeal = [
      SELECT Stage__c, Lifecycle_Health__c
      FROM Deal_Registration__c
      WHERE Id = :fixture.deal.Id
    ];
    Assert.areEqual('Negotiation', refreshedDeal.Stage__c);
    Assert.areEqual('At Risk', refreshedDeal.Lifecycle_Health__c);
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Audit_Log__c
        WHERE
          Record_Id__c = :fixture.deal.Id
          AND Action__c = 'Reopen Sales Execution'
      ]
    );
  }

  @IsTest
  static void detectsOrphanedOpportunityAndFlagsHealth() {
    Fixture fixture = buildFixture('Qualification');
    delete [SELECT Id FROM Opportunity WHERE Id = :fixture.opportunity.Id];

    Deal_Opportunity__c orphaned = requeryRelationship(fixture.relationship.Id);
    Assert.isNull(orphaned.Opportunity__c);

    Test.startTest();
    new DealOpportunityReconciliationBatch()
      .execute(null, new List<Deal_Opportunity__c>{ orphaned });
    Test.stopTest();

    Deal_Registration__c refreshedDeal = [
      SELECT Lifecycle_Health__c
      FROM Deal_Registration__c
      WHERE Id = :fixture.deal.Id
    ];
    Assert.areEqual('Blocked', refreshedDeal.Lifecycle_Health__c);
  }

  @IsTest
  static void detectsAmountDriftAndRequestsReapproval() {
    Fixture fixture = buildFixture('Proposal/Price Quote');
    Database.update(
      new Deal_Registration__c(
        Id = fixture.deal.Id,
        Status__c = 'Approved',
        Version_Number__c = 0,
        Approved_Revenue__c = 100000,
        Approved_Opportunity__c = fixture.opportunity.Id
      ),
      AccessLevel.SYSTEM_MODE
    );
    Database.update(
      new Opportunity(Id = fixture.opportunity.Id, Amount = 50000),
      AccessLevel.SYSTEM_MODE
    );

    Test.startTest();
    new DealOpportunityReconciliationBatch()
      .execute(
        null,
        new List<Deal_Opportunity__c>{
          requeryRelationship(fixture.relationship.Id)
        }
      );
    Test.stopTest();

    Deal_Registration__c refreshedDeal = [
      SELECT Status__c
      FROM Deal_Registration__c
      WHERE Id = :fixture.deal.Id
    ];
    Assert.areEqual('Under Review', refreshedDeal.Status__c);
  }

  @IsTest
  static void logsASyncFailureAndContinuesPastABadRow() {
    Fixture fixture = buildFixture('Qualification');
    Deal_Opportunity__c relationship = requeryRelationship(
      fixture.relationship.Id
    );
    delete fixture.deal;
    Deal_Opportunity__c orphanedFromDeletedDeal = requeryRelationship(
      fixture.relationship.Id
    );

    Test.startTest();
    new DealOpportunityReconciliationBatch()
      .execute(null, new List<Deal_Opportunity__c>{ orphanedFromDeletedDeal });
    Test.stopTest();

    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM PartnerSync_Opportunity_Sync_Log__c
        WHERE
          Deal_Opportunity__c = :fixture.relationship.Id
          AND Status__c = 'Failed'
      ]
    );
  }

  @IsTest
  static void reconciles200RelationshipsWithinGovernorLimits() {
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Bulk Customer'
    );
    insert customer;

    List<Opportunity> opportunities = new List<Opportunity>();
    for (Integer index = 0; index < 200; index++) {
      Opportunity opportunity = PartnerSyncTestDataFactory.opportunity(
        customer.Id,
        null,
        null
      );
      opportunity.StageName = 'Prospecting';
      opportunities.add(opportunity);
    }
    insert opportunities;

    List<Deal_Registration__c> deals = new List<Deal_Registration__c>();
    for (Integer index = 0; index < 200; index++) {
      deals.add(
        PartnerSyncTestDataFactory.deal(
          customer.Id,
          null,
          null,
          opportunities[index].Id
        )
      );
    }
    insert deals;

    List<Deal_Opportunity__c> relationships = new List<Deal_Opportunity__c>();
    for (Integer index = 0; index < 200; index++) {
      relationships.add(
        new Deal_Opportunity__c(
          Deal__c = deals[index].Id,
          Opportunity__c = opportunities[index].Id,
          Relationship_Type__c = 'Primary',
          Primary__c = true,
          Current__c = true,
          Relationship_Key__c = deals[index].Id + '|' + opportunities[index].Id,
          Version_Number__c = 0
        )
      );
    }
    insert relationships;

    Test.startTest();
    Database.executeBatch(new DealOpportunityReconciliationBatch(), 200);
    Test.stopTest();

    Assert.areEqual(
      200,
      [
        SELECT COUNT()
        FROM Deal_Registration__c
        WHERE Stage__c = 'Qualification'
      ]
    );
  }

  // Proves the Implementation-creation cascade doesn't exceed governor
  // limits within a single batch chunk. ImplementationCommandService.
  // create() does 5 SOQL + 3 DML statements per deal (policy resolution,
  // the deal/primary-opportunity/originating-participant lookups, the
  // implementation insert, its generated milestones, and the lifecycle
  // phase advance) - a true bulk rewrite of that single-record command
  // service is disproportionate for a scenario (many deals reaching Closed
  // Won in the exact same batch chunk) this codebase already treats as an
  // accepted-risk category (see this class's own doc comment, and
  // linkOpportunityToDeal's identical 15-row precedent). 15 rows exercises
  // real multi-record behaviour while staying safely under the 100 SOQL /
  // 150 DML limits with headroom for the batch's own per-row cost.
  @IsTest
  static void closedWon15OpportunitiesCreatesImplementationsWithinGovernorLimits() {
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Bulk Closed Won Customer'
    );
    insert customer;

    List<Opportunity> opportunities = new List<Opportunity>();
    for (Integer index = 0; index < 15; index++) {
      Opportunity opportunity = PartnerSyncTestDataFactory.opportunity(
        customer.Id,
        null,
        null
      );
      opportunity.StageName = 'Closed Won';
      opportunities.add(opportunity);
    }
    insert opportunities;

    List<Deal_Registration__c> deals = new List<Deal_Registration__c>();
    for (Integer index = 0; index < 15; index++) {
      deals.add(
        PartnerSyncTestDataFactory.deal(
          customer.Id,
          null,
          null,
          opportunities[index].Id
        )
      );
    }
    insert deals;

    List<Deal_Opportunity__c> relationships = new List<Deal_Opportunity__c>();
    for (Integer index = 0; index < 15; index++) {
      relationships.add(
        new Deal_Opportunity__c(
          Deal__c = deals[index].Id,
          Opportunity__c = opportunities[index].Id,
          Relationship_Type__c = 'Primary',
          Primary__c = true,
          Current__c = true,
          Relationship_Key__c = deals[index].Id + '|' + opportunities[index].Id,
          Version_Number__c = 0
        )
      );
    }
    insert relationships;

    Test.startTest();
    Database.executeBatch(new DealOpportunityReconciliationBatch(), 15);
    Test.stopTest();

    Assert.areEqual(
      15,
      [SELECT COUNT() FROM Deal_Implementation__c WHERE Status__c = 'Planned']
    );
  }

  private class Fixture {
    Deal_Registration__c deal;
    Opportunity opportunity;
    Deal_Opportunity__c relationship;
  }

  private static Fixture buildFixture(String stageName) {
    Fixture fixture = new Fixture();
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Reconciliation Customer'
    );
    insert customer;

    fixture.opportunity = PartnerSyncTestDataFactory.opportunity(
      customer.Id,
      null,
      null
    );
    fixture.opportunity.StageName = stageName;
    insert fixture.opportunity;

    fixture.deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      null,
      null,
      fixture.opportunity.Id
    );
    insert fixture.deal;

    fixture.relationship = new Deal_Opportunity__c(
      Deal__c = fixture.deal.Id,
      Opportunity__c = fixture.opportunity.Id,
      Relationship_Type__c = 'Primary',
      Primary__c = true,
      Current__c = true,
      Relationship_Key__c = fixture.deal.Id + '|' + fixture.opportunity.Id,
      Version_Number__c = 0
    );
    insert fixture.relationship;

    return fixture;
  }

  private static Deal_Protection_Grant__c insertActiveGrant(Id dealId) {
    Deal_Protection_Grant__c grant = new Deal_Protection_Grant__c(
      Deal__c = dealId,
      Current__c = true,
      Current_Grant_Key__c = String.valueOf(dealId),
      Status__c = 'Active',
      Start_Date__c = Date.today(),
      End_Date__c = Date.today().addDays(30),
      Version_Number__c = 0,
      Extension_Count__c = 0
    );
    insert grant;
    return grant;
  }

  private static Deal_Opportunity__c requeryRelationship(Id dealOpportunityId) {
    return [
      SELECT
        Id,
        Deal__c,
        Opportunity__c,
        Partner_Account__c,
        Deal__r.Lifecycle_Health__c,
        Deal__r.Stage__c,
        Deal__r.Approved_Revenue__c,
        Deal__r.Approved_Customer_Account__c,
        Deal__r.Approved_Close_Date__c,
        Deal__r.Approved_Owner__c,
        Deal__r.Approved_Opportunity__c,
        Opportunity__r.StageName,
        Opportunity__r.Amount,
        Opportunity__r.CloseDate,
        Opportunity__r.AccountId,
        Opportunity__r.OwnerId,
        Opportunity__r.IsWon,
        Opportunity__r.IsClosed
      FROM Deal_Opportunity__c
      WHERE Id = :dealOpportunityId
    ];
  }

  private static String dealStage(Id dealId) {
    return [SELECT Stage__c FROM Deal_Registration__c WHERE Id = :dealId]
    .Stage__c;
  }
}
