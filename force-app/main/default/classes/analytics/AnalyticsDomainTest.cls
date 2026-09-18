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

    Opportunity wonOpp = opportunityState(true, true, 12000);

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
    System.assertEquals(2, dto.acceptedLeads);
    System.assertEquals(1, dto.convertedLeads);
    System.assertEquals(2, dto.totalDeals);
    System.assertEquals(1, dto.approvedDeals);
    System.assertEquals(12000, dto.totalRevenue);
    System.assertEquals(8000, dto.mdfRemaining);
    Assert.areEqual(1, dto.leadAcceptanceRate);
    Assert.areEqual(1, dto.dealWinRate);
    Assert.areEqual(30000, dto.totalPipeline);
    // 20 acceptance + 12.5 conversion + 30 wins + 8 revenue + 1 MDF.
    Assert.areEqual(72, dto.healthScore);
    Assert.areEqual('Healthy', dto.healthLabel);
    System.assertEquals(5, dto.healthSignals.size());
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
    kpi.healthScore = 31;

    PartnerLeaderboardRowDTO row = AnalyticsDomain.buildLeaderboardRow(
      partner,
      kpi
    );

    System.assertEquals('Partner', row.partnerName);
    System.assertEquals(50000, row.revenue);
    System.assertEquals(31, row.score);
  }

  @IsTest
  static void healthScoreIsBoundedAndTiered() {
    PartnerKPIDTO kpi = new PartnerKPIDTO();
    kpi.leadAcceptanceRate = 2;
    kpi.leadConversionRate = 1;
    kpi.dealWinRate = 1;
    kpi.totalRevenue = 200;
    kpi.totalPipeline = 100;
    kpi.mdfUtilisationRate = 1.5;

    System.assertEquals(100, PartnerHealthScoringService.calculate(kpi));
    System.assertEquals(
      'Thriving',
      PartnerHealthScoringService.healthLabel(100)
    );
    System.assertEquals(
      'Strategic',
      PartnerHealthScoringService.recommendTier(100)
    );
  }

  @IsTest
  static void conversionPreservesAcceptanceAndPipelineExcludesTerminalDeals() {
    Lead lead = new Lead(Lead_Distribution_Status__c = 'Accepted');
    List<Deal_Registration__c> deals = new List<Deal_Registration__c>();
    for (
      String status : new List<String>{
        'Submitted',
        'Needs Information',
        'Under Review',
        'Approved',
        'Draft',
        'Rejected',
        'Cancelled',
        'Expired',
        'Converted',
        'Closed Won',
        'Closed Lost'
      }
    ) {
      deals.add(
        new Deal_Registration__c(Status__c = status, Estimated_Revenue__c = 100)
      );
    }
    deals.add(new Deal_Registration__c(Status__c = 'Submitted'));
    List<Opportunity> opportunities = new List<Opportunity>{
      opportunityState(true, true, 200),
      opportunityState(true, false, 300),
      opportunityState(false, false, 400)
    };
    Account budget = new Account();
    PartnerKPIDTO beforeConversion = AnalyticsDomain.calculatePartnerKPI(
      new List<Lead>{ lead },
      deals,
      opportunities,
      budget
    );
    lead.Lead_Distribution_Status__c = 'Converted';
    PartnerKPIDTO afterConversion = AnalyticsDomain.calculatePartnerKPI(
      new List<Lead>{ lead },
      deals,
      opportunities,
      budget
    );
    Assert.areEqual(1, afterConversion.leadAcceptanceRate);
    Assert.areEqual(
      beforeConversion.leadAcceptanceRate,
      afterConversion.leadAcceptanceRate
    );
    Assert.areEqual(1, afterConversion.leadConversionRate);
    Assert.areEqual(400, afterConversion.totalPipeline);
    Assert.areEqual(200, afterConversion.totalRevenue);
    Assert.areEqual(
      0.5,
      afterConversion.dealWinRate,
      'Win rate uses won / (won + lost), excluding open opportunities and registrations.'
    );
  }

  @IsTest
  static void emptyActivityAndOpenOnlyOpportunitiesHaveZeroWinRate() {
    PartnerKPIDTO empty = AnalyticsDomain.calculatePartnerKPI(
      new List<Lead>(),
      new List<Deal_Registration__c>(),
      new List<Opportunity>(),
      new Account()
    );
    Assert.areEqual(0, empty.leadAcceptanceRate);
    Assert.areEqual(0, empty.leadConversionRate);
    Assert.areEqual(0, empty.dealWinRate);
    Assert.areEqual(0, empty.totalRevenue);
    Assert.areEqual(0, empty.totalPipeline);
    Assert.areEqual(0, empty.mdfUtilisationRate);
    PartnerKPIDTO openOnly = AnalyticsDomain.calculatePartnerKPI(
      new List<Lead>(),
      new List<Deal_Registration__c>(),
      new List<Opportunity>{ opportunityState(false, false, 500) },
      new Account()
    );
    Assert.areEqual(0, openOnly.dealWinRate);
    Assert.areEqual(0, openOnly.totalRevenue);
  }

  private static Opportunity opportunityState(
    Boolean closed,
    Boolean won,
    Decimal amount
  ) {
    // These platform-calculated fields are populated by SOQL in production.
    // Deserialisation models them without assuming a subscriber's stage names.
    return (Opportunity) JSON.deserialize(
      JSON.serialize(
        new Map<String, Object>{
          'IsClosed' => closed,
          'IsWon' => won,
          'Amount' => amount,
          'StageName' => 'Subscriber-defined stage'
        }
      ),
      Opportunity.class
    );
  }
}
