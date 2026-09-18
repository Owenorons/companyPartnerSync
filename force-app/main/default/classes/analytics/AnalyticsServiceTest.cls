/*
 * Tests AnalyticsService's permission gating: confirms executive/internal
 * admin users can reach cross-partner analytics while a plain Channel
 * Manager or internal user without the executive-analytics permission is
 * blocked.
 */
@IsTest
private class AnalyticsServiceTest {
  @IsTest
  static void executiveCanViewExecutiveAnalytics() {
    User executiveUser = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      executiveUser.Id,
      'PartnerSync_Executive_User'
    );

    System.runAs(executiveUser) {
      List<PartnerLeaderboardRowDTO> leaderboard = AnalyticsService.getPartnerLeaderboard();
      System.assertNotEquals(null, leaderboard);

      List<CustomerRevenueDTO> revenue = AnalyticsService.getCustomerRevenue();
      System.assertNotEquals(null, revenue);
    }
  }

  @IsTest
  static void internalAdminCanViewExecutiveAnalytics() {
    User internalAdmin = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      internalAdmin.Id,
      'PartnerSync_Internal_Admin'
    );

    System.runAs(internalAdmin) {
      System.assertNotEquals(null, AnalyticsService.getPartnerLeaderboard());
    }
  }

  @IsTest
  static void channelManagerWithoutExecutivePermissionIsBlocked() {
    User channelManager = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      Boolean threw = false;

      try {
        AnalyticsService.getPartnerLeaderboard();
      } catch (PartnerSyncHandledException ex) {
        threw = true;
      }

      System.assertEquals(
        true,
        threw,
        'Channel Manager needs the optional executive-analytics custom permission.'
      );
    }
  }

  @IsTest
  static void plainInternalUserIsBlockedFromCustomerRevenue() {
    User plainInternalUser = TestUserFactory.createInternalUser();

    System.runAs(plainInternalUser) {
      Boolean threw = false;

      try {
        AnalyticsService.getCustomerRevenue();
      } catch (PartnerSyncHandledException ex) {
        threw = true;
      }

      System.assertEquals(true, threw);
    }
  }

  @IsTest
  static void executiveAnalyticsAggregatesPopulatedPartnerData() {
    User executiveUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      executiveUser.Id,
      'PartnerSync_Executive_User'
    );
    System.runAs(executiveUser) {
      Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
      partner.Partner_Status__c = 'Active';
      partner.MDF_Annual_Budget__c = 10000;
      partner.MDF_Used__c = 2500;
      Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
      insert new List<Account>{ partner, customer };
      insert new Lead(
        LastName = 'Buyer',
        Company = 'Customer',
        Partner_Account__c = partner.Id,
        Lead_Distribution_Status__c = 'Accepted'
      );
      insert new Deal_Registration__c(
        Partner_Account__c = partner.Id,
        Status__c = 'Approved',
        Estimated_Revenue__c = 5000
      );
      insert new List<Opportunity>{
        new Opportunity(
          Name = 'Won One',
          AccountId = customer.Id,
          Partner_Account__c = partner.Id,
          StageName = 'Closed Won',
          CloseDate = Date.today(),
          Amount = 2000
        ),
        new Opportunity(
          Name = 'Won Two',
          AccountId = customer.Id,
          Partner_Account__c = partner.Id,
          StageName = 'Closed Won',
          CloseDate = Date.today(),
          Amount = null
        )
      };

      List<PartnerLeaderboardRowDTO> leaderboard = AnalyticsService.getPartnerLeaderboard();
      PartnerLeaderboardRowDTO partnerRow;
      for (PartnerLeaderboardRowDTO row : leaderboard) {
        if (row.partnerAccountId == partner.Id)
          partnerRow = row;
      }
      Assert.isNotNull(partnerRow);
      Assert.areEqual(2000, partnerRow.revenue);

      List<CustomerRevenueDTO> revenue = AnalyticsService.getCustomerRevenue();
      Assert.areEqual(1, revenue.size());
      Assert.areEqual('Customer', revenue[0].customerName);
      Assert.areEqual('Partner', revenue[0].partnerName);
      Assert.areEqual(2000, revenue[0].revenue);
      Assert.areEqual(2, revenue[0].opportunityCount);
      Assert.areEqual(
        partner.Id,
        AnalyticsSelector.selectPartnerBudget(partner.Id).Id
      );
      try {
        AnalyticsSelector.selectPartnerBudget(UserInfo.getUserId());
        Assert.fail('Expected missing partner rejection.');
      } catch (PartnerSyncHandledException expected) {
        Assert.isTrue(expected.getMessage().contains('not found'));
      }
    }
  }

  @IsTest
  static void leaderboardScalesAndKeepsPartnerMetricsIsolated() {
    User executiveUser = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      executiveUser.Id,
      'PartnerSync_Internal_Admin'
    );
    System.runAs(executiveUser) {
      List<Account> partners = new List<Account>();
      for (Integer i = 0; i < 30; i++) {
        partners.add(
          PartnerSyncTestDataFactory.partnerAccount('Scale Partner ' + i)
        );
      }
      insert partners;
      Account emptyPartner = PartnerSyncTestDataFactory.partnerAccount(
        'No Activity'
      );
      insert emptyPartner;
      List<Lead> leads = new List<Lead>();
      List<Opportunity> opportunities = new List<Opportunity>();
      List<Deal_Registration__c> deals = new List<Deal_Registration__c>();
      for (Integer i = 0; i < partners.size(); i++) {
        Account partner = partners[i];
        for (
          String status : new List<String>{
            'Accepted',
            'Converted',
            'Assigned'
          }
        ) {
          leads.add(
            new Lead(
              LastName = status,
              Company = 'Scale',
              Partner_Account__c = partner.Id,
              Lead_Distribution_Status__c = status
            )
          );
        }
        deals.add(
          new Deal_Registration__c(
            Partner_Account__c = partner.Id,
            Status__c = 'Submitted',
            Estimated_Revenue__c = 1000
          )
        );
        for (
          String stage : new List<String>{
            'Closed Won',
            'Closed Lost',
            'Qualification'
          }
        ) {
          opportunities.add(
            new Opportunity(
              Name = stage,
              Partner_Account__c = partner.Id,
              StageName = stage,
              CloseDate = Date.today(),
              Amount = 100 + i
            )
          );
        }
      }
      insert leads;
      insert deals;
      insert opportunities;
      Test.startTest();
      Integer queriesBefore = Limits.getQueries();
      List<PartnerLeaderboardRowDTO> rows = AnalyticsService.getPartnerLeaderboard();
      Integer queriesUsed = Limits.getQueries() - queriesBefore;
      Test.stopTest();
      Assert.areEqual(31, rows.size());
      Assert.isTrue(
        queriesUsed <= 13,
        'Expected nine data queries plus four permission checks, got ' +
        queriesUsed
      );
      Map<Id, PartnerLeaderboardRowDTO> byPartner = new Map<Id, PartnerLeaderboardRowDTO>();
      for (PartnerLeaderboardRowDTO row : rows) {
        byPartner.put(row.partnerAccountId, row);
      }
      for (Integer i = 0; i < partners.size(); i++) {
        PartnerLeaderboardRowDTO row = byPartner.get(partners[i].Id);
        Assert.areEqual(2, row.acceptedLeads);
        Assert.areEqual(1, row.wonDeals);
        Assert.areEqual(100 + i, row.revenue);
        Assert.areEqual(0.5, row.conversionRate);
      }
      Assert.areEqual(0, byPartner.get(emptyPartner.Id).revenue);
      Assert.areEqual(0, byPartner.get(emptyPartner.Id).conversionRate);
      Id firstId = partners[0].Id;
      AnalyticsDomain.KpiTotals totals = AnalyticsSelector.selectKpiTotals(
          new Set<Id>{ firstId }
        )
        .get(firstId);
      PartnerKPIDTO kpi = AnalyticsDomain.calculatePartnerKPI(
        totals,
        partners[0]
      );
      Assert.areEqual(1000, kpi.totalPipeline);
      Assert.areEqual(3, kpi.totalLeads);
      Assert.areEqual(1, kpi.convertedLeads);
      Assert.areEqual(kpi.healthScore, byPartner.get(firstId).score);
      Assert.areEqual(
        kpi.healthScore,
        PartnerHealthScoringService.calculate(firstId)
      );
    }
  }
}
