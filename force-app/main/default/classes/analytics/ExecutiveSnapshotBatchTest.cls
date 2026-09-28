/*
 * Covers ExecutiveSnapshotBatch.compute(): computes correct org-wide
 * aggregates from a real multi-partner Partner_Portfolio_Snapshot__c
 * fixture, re-running for the same day updates the existing row rather
 * than duplicating it (the concurrency-shaped idempotency pair), and a
 * day with zero snapshots produces a well-formed zeroed row rather than
 * erroring.
 */
@IsTest
private class ExecutiveSnapshotBatchTest {
  @IsTest
  static void computesCorrectOrgWideAggregates() {
    Account partnerOne = PartnerSyncTestDataFactory.partnerAccount(
      'Executive Snapshot Partner One'
    );
    Account partnerTwo = PartnerSyncTestDataFactory.partnerAccount(
      'Executive Snapshot Partner Two'
    );
    insert new List<Account>{ partnerOne, partnerTwo };

    insert new Partner_Portfolio_Snapshot__c(
      Partner_Account__c = partnerOne.Id,
      Snapshot_Date__c = Date.today(),
      Health_Score__c = 80,
      Open_Deal_Count__c = 3,
      At_Risk_Deal_Count__c = 1,
      Active_Engagement_Count__c = 2,
      At_Risk_Engagement_Count__c = 0,
      Upcoming_Renewal_Count__c = 1,
      Renewal_Value_At_Risk__c = 50000,
      Open_Expansion_Count__c = 1,
      Churned_Engagement_Count_Trailing_12mo__c = 0,
      Total_Revenue_Trailing_12mo__c = 100000
    );
    insert new Partner_Portfolio_Snapshot__c(
      Partner_Account__c = partnerTwo.Id,
      Snapshot_Date__c = Date.today(),
      Health_Score__c = 40,
      Open_Deal_Count__c = 2,
      At_Risk_Deal_Count__c = 2,
      Active_Engagement_Count__c = 1,
      At_Risk_Engagement_Count__c = 1,
      Upcoming_Renewal_Count__c = 0,
      Renewal_Value_At_Risk__c = 0,
      Open_Expansion_Count__c = 0,
      Churned_Engagement_Count_Trailing_12mo__c = 1,
      Total_Revenue_Trailing_12mo__c = 50000
    );
    AI_Interaction__c interaction = new AI_Interaction__c(
      Use_Case_Key__c = 'RenewalRiskAdvisor',
      Status__c = 'Succeeded'
    );
    insert interaction;
    insert new AI_Recommendation__c(
      Interaction__c = interaction.Id,
      Recommended_Action_Key__c = 'RequestRenewalReview',
      Recommendation_Text__c = 'Test recommendation.',
      Status__c = 'Proposed'
    );

    Test.startTest();
    Executive_Snapshot__c snapshot = ExecutiveSnapshotBatch.compute();
    Test.stopTest();

    Assert.areEqual(2, snapshot.Active_Partner_Count__c);
    Assert.areEqual(60, snapshot.Average_Health_Score__c);
    Assert.areEqual(5, snapshot.Total_Open_Deal_Count__c);
    Assert.areEqual(3, snapshot.Total_At_Risk_Deal_Count__c);
    Assert.areEqual(3, snapshot.Total_Active_Engagement_Count__c);
    Assert.areEqual(1, snapshot.Total_At_Risk_Engagement_Count__c);
    Assert.areEqual(1, snapshot.Total_Upcoming_Renewal_Count__c);
    Assert.areEqual(50000, snapshot.Total_Renewal_Value_At_Risk__c);
    Assert.areEqual(1, snapshot.Total_Open_Expansion_Count__c);
    Assert.areEqual(
      1,
      snapshot.Total_Churned_Engagement_Count_Trailing_12mo__c
    );
    Assert.areEqual(150000, snapshot.Total_Revenue_Trailing_12mo__c);
    Assert.areEqual(1, snapshot.Open_AI_Recommendation_Count__c);
    Assert.isNotNull(snapshot.Computed_On__c);
  }

  @IsTest
  static void reRunningForTheSameDayUpdatesRatherThanDuplicates() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount(
      'Idempotency Test Partner'
    );
    insert partner;
    insert new Partner_Portfolio_Snapshot__c(
      Partner_Account__c = partner.Id,
      Snapshot_Date__c = Date.today(),
      Health_Score__c = 70,
      Open_Deal_Count__c = 1
    );

    Executive_Snapshot__c first = ExecutiveSnapshotBatch.compute();

    Account secondPartner = PartnerSyncTestDataFactory.partnerAccount(
      'Idempotency Test Partner Two'
    );
    insert secondPartner;
    insert new Partner_Portfolio_Snapshot__c(
      Partner_Account__c = secondPartner.Id,
      Snapshot_Date__c = Date.today(),
      Health_Score__c = 90,
      Open_Deal_Count__c = 4
    );

    Executive_Snapshot__c second = ExecutiveSnapshotBatch.compute();

    Assert.areEqual(
      first.Id,
      second.Id,
      'Re-running for the same day must update the existing row, not create a new one.'
    );
    Assert.areEqual(2, second.Active_Partner_Count__c);
    Assert.areEqual(
      1,
      [
        SELECT COUNT()
        FROM Executive_Snapshot__c
        WHERE Snapshot_Date__c = :Date.today()
      ]
    );
  }

  @IsTest
  static void aDayWithZeroSnapshotsProducesAWellFormedZeroedRow() {
    Executive_Snapshot__c snapshot = ExecutiveSnapshotBatch.compute();

    Assert.areEqual(0, snapshot.Active_Partner_Count__c);
    Assert.areEqual(0, snapshot.Average_Health_Score__c);
    Assert.areEqual(0, snapshot.Total_Open_Deal_Count__c);
    Assert.areEqual(0, snapshot.Total_Revenue_Trailing_12mo__c);
    Assert.areEqual(0, snapshot.Open_AI_Recommendation_Count__c);
  }
}
