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
}
