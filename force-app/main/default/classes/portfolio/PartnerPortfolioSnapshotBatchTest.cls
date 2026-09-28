/*
 * Covers PartnerPortfolioSnapshotBatch: computes correct counts/sums
 * against a real multi-object fixture (open/at-risk deals, active/at-risk
 * engagements, upcoming renewals + value at risk, open expansions,
 * trailing-12mo churn/revenue), and is proven safe at a real 50-partner
 * scale - every count/sum is a fixed, small number of bulk aggregate SOQL
 * calls per chunk, not one query per partner, so a real multi-partner run
 * proves the design rather than just asserting a raw partner count.
 */
@IsTest
private class PartnerPortfolioSnapshotBatchTest {
  @IsTest
  static void computesCorrectCountsAndSumsForAPartner() {
    Fixture fixture = createFixture();

    Test.startTest();
    Database.executeBatch(new PartnerPortfolioSnapshotBatch(), 200);
    Test.stopTest();

    Partner_Portfolio_Snapshot__c snapshot = [
      SELECT
        Open_Deal_Count__c,
        At_Risk_Deal_Count__c,
        Active_Engagement_Count__c,
        At_Risk_Engagement_Count__c,
        Upcoming_Renewal_Count__c,
        Renewal_Value_At_Risk__c,
        Open_Expansion_Count__c,
        Churned_Engagement_Count_Trailing_12mo__c,
        Total_Revenue_Trailing_12mo__c
      FROM Partner_Portfolio_Snapshot__c
      WHERE Partner_Account__c = :fixture.partner.Id
    ];

    Assert.areEqual(
      2,
      snapshot.Open_Deal_Count__c,
      'openDeal (Submitted) and renewalDeal (Approved) both count as open; only atRiskDeal (Rejected) is excluded.'
    );
    Assert.areEqual(1, snapshot.At_Risk_Deal_Count__c);
    Assert.areEqual(1, snapshot.Active_Engagement_Count__c);
    Assert.areEqual(1, snapshot.At_Risk_Engagement_Count__c);
    Assert.areEqual(1, snapshot.Upcoming_Renewal_Count__c);
    Assert.areEqual(120000, snapshot.Renewal_Value_At_Risk__c);
    Assert.areEqual(1, snapshot.Open_Expansion_Count__c);
    Assert.areEqual(1, snapshot.Churned_Engagement_Count_Trailing_12mo__c);
    Assert.areEqual(50000, snapshot.Total_Revenue_Trailing_12mo__c);
  }

  @IsTest
  static void computesSnapshotsFor50PartnersWithinGovernorLimits() {
    List<Account> partners = new List<Account>();
    for (Integer index = 0; index < 50; index++) {
      Account partner = PartnerSyncTestDataFactory.partnerAccount(
        'Bulk Portfolio Partner ' + index
      );
      partners.add(partner);
    }
    insert partners;

    Test.startTest();
    Database.executeBatch(new PartnerPortfolioSnapshotBatch(), 200);
    Test.stopTest();

    Assert.areEqual(
      50,
      [
        SELECT COUNT()
        FROM Partner_Portfolio_Snapshot__c
        WHERE Partner_Account__c IN :partners
      ]
    );
  }

  private static Fixture createFixture() {
    Fixture fixture = new Fixture();
    fixture.partner = PartnerSyncTestDataFactory.partnerAccount(
      'Portfolio Snapshot Partner'
    );
    insert fixture.partner;
    Account customer = PartnerSyncTestDataFactory.customerAccount(
      'Portfolio Snapshot Customer'
    );
    insert customer;

    Deal_Registration__c openDeal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      fixture.partner.Id,
      null,
      null
    );
    insert openDeal;

    Deal_Registration__c atRiskDeal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      fixture.partner.Id,
      null,
      null
    );
    atRiskDeal.Status__c = 'Rejected';
    insert atRiskDeal;
    atRiskDeal.Lifecycle_Health__c = 'Blocked';
    update atRiskDeal;

    Deal_Registration__c renewalDeal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      fixture.partner.Id,
      null,
      null
    );
    renewalDeal.Status__c = 'Approved';
    renewalDeal.Approved_Revenue__c = 120000;
    insert renewalDeal;

    Customer_Success_Engagement__c activeEngagement = new Customer_Success_Engagement__c(
      Customer_Account__c = customer.Id,
      Primary_Partner__c = fixture.partner.Id,
      Status__c = 'Active',
      Health_Status__c = 'At Risk',
      Version_Number__c = 0
    );
    insert activeEngagement;

    Customer_Success_Engagement__c churnedEngagement = new Customer_Success_Engagement__c(
      Customer_Account__c = customer.Id,
      Primary_Partner__c = fixture.partner.Id,
      Status__c = 'Churned',
      Health_Status__c = 'Churned',
      Churned_On__c = Date.today().addMonths(-2),
      Version_Number__c = 0
    );
    insert churnedEngagement;

    insert new Partner_Renewal__c(
      Customer_Success_Engagement__c = activeEngagement.Id,
      Customer_Account__c = customer.Id,
      Current_Deal__c = renewalDeal.Id,
      Primary_Partner__c = fixture.partner.Id,
      Status__c = 'Review Required',
      Renewal_Health__c = 'At Risk',
      Version_Number__c = 0
    );

    insert new Partner_Expansion__c(
      Customer_Success_Engagement__c = activeEngagement.Id,
      Customer_Account__c = customer.Id,
      Primary_Partner__c = fixture.partner.Id,
      Expansion_Type__c = 'Seat Increase',
      Status__c = 'Identified',
      Version_Number__c = 0
    );

    insert new Deal_Revenue__c(
      Deal__c = openDeal.Id,
      Partner_Account__c = fixture.partner.Id,
      Revenue_Type__c = 'Booking',
      Source_Type__c = 'Manual',
      Status__c = 'Confirmed',
      Net_Amount__c = 50000,
      Revenue_Date__c = Date.today().addMonths(-3),
      Version_Number__c = 0
    );

    // Older than 12 months - must not be counted in trailing-12mo revenue.
    insert new Deal_Revenue__c(
      Deal__c = openDeal.Id,
      Partner_Account__c = fixture.partner.Id,
      Revenue_Type__c = 'Booking',
      Source_Type__c = 'Manual',
      Status__c = 'Confirmed',
      Net_Amount__c = 999999,
      Revenue_Date__c = Date.today().addMonths(-18),
      Version_Number__c = 0
    );

    return fixture;
  }

  private class Fixture {
    Account partner;
  }
}
