/*
 * Unit tests for AnalyticsDomain's pure calculation methods. Exercises the
 * KPI aggregation and leaderboard scoring math directly against in-memory
 * SObjects, without inserting records or asserting permissions.
 */
@IsTest
private class AnalyticsDomainTest {
  @IsTest
  static void calculatePartnerKpiAggregatesMetrics() {
    Lead acceptedLead = new Lead(
      LastName = 'Accepted',
      Company = 'Acme',
      Status = 'Open - Not Contacted',
      Lead_Distribution_Status__c = 'Accepted'
    );
    Lead convertedLead = new Lead(
      LastName = 'Converted',
      Company = 'Acme',
      Status = 'Open - Not Contacted',
      Lead_Distribution_Status__c = 'Converted'
    );

    Deal_Registration__c approvedDeal = new Deal_Registration__c(
      Status__c = 'Approved',
      Estimated_Revenue__c = 20000
    );
    Deal_Registration__c submittedDeal = new Deal_Registration__c(
      Status__c = 'Submitted',
      Estimated_Revenue__c = 10000
    );

    Opportunity wonOpp = new Opportunity(
      Name = 'Won',
      StageName = 'Closed Won',
      CloseDate = Date.today(),
      Amount = 12000
    );

    Account budget = new Account(
      Name = 'Partner',
      MDF_Annual_Budget__c = 10000,
      MDF_Used__c = 2000
    );

    PartnerKPIDTO dto = AnalyticsDomain.calculatePartnerKPI(
      new List<Lead>{ acceptedLead, convertedLead },
      new List<Deal_Registration__c>{ approvedDeal, submittedDeal },
      new List<Opportunity>{ wonOpp },
      budget
    );

    System.assertEquals(2, dto.totalLeads);
    System.assertEquals(1, dto.acceptedLeads);
    System.assertEquals(1, dto.convertedLeads);
    System.assertEquals(2, dto.totalDeals);
    System.assertEquals(1, dto.approvedDeals);
    System.assertEquals(12000, dto.totalRevenue);
    System.assertEquals(8000, dto.mdfRemaining);
  }

  @IsTest
  static void buildLeaderboardRowCalculatesScore() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    PartnerKPIDTO kpi = new PartnerKPIDTO();
    kpi.acceptedLeads = 2;
    kpi.approvedDeals = 3;
    kpi.wonDeals = 1;
    kpi.totalRevenue = 50000;
    kpi.leadAcceptanceRate = 0.5;
    kpi.leadConversionRate = 0.25;
    kpi.dealWinRate = 0.2;
    kpi.mdfUtilisationRate = 0.1;

    PartnerLeaderboardRowDTO row = AnalyticsDomain.buildLeaderboardRow(
      partner,
      kpi
    );

    System.assertEquals('Partner', row.partnerName);
    System.assertEquals(50000, row.revenue);
    System.assert(row.score > 0, 'Expected a positive leaderboard score.');
  }
}
