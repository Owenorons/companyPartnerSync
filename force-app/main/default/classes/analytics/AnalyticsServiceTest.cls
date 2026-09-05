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
      'PartnerSync_Internal_Admin'
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
}
