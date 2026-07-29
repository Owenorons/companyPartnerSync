/*
 * Verifies InternalDashboardService's permission-gated counts: a user with
 * the review permission set sees real counts and alerts, while a plain
 * internal user sees zeros instead of an error.
 */
@IsTest
private class InternalDashboardServiceTest {
  @IsTest
  static void channelManagerSeesPendingCountsAndAlerts() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      partner.Id,
      null,
      null
    );
    insert deal;

    MDF_Request__c mdfRequest = PartnerSyncTestDataFactory.mdfRequest(
      partner.Id,
      null
    );
    insert mdfRequest;

    User channelManager = TestUserFactory.createInternalUser();

    TestUserFactory.assignPermissionSet(
      channelManager.Id,
      'PartnerSync_Channel_Manager'
    );

    System.runAs(channelManager) {
      insert new Partner_Notification__c(
        Recipient_User__c = channelManager.Id,
        Title__c = 'Heads up',
        Message__c = 'Something needs attention.',
        Is_Read__c = false,
        Dismissed__c = false
      );

      InternalDashboardDTO dto = InternalDashboardService.getDashboard();

      System.assertEquals(1, dto.pendingDealReviewCount);
      System.assertEquals(1, dto.pendingMdfReviewCount);
      System.assertEquals(1, dto.unreadNotificationCount);
      System.assertEquals(
        3,
        dto.alerts.size(),
        'A deal, MDF, and notification alert should each be present.'
      );
    }
  }

  @IsTest
  static void plainInternalUserSeesZeroRestrictedCounts() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Account customer = PartnerSyncTestDataFactory.customerAccount('Customer');
    insert customer;

    Deal_Registration__c deal = PartnerSyncTestDataFactory.deal(
      customer.Id,
      partner.Id,
      null,
      null
    );
    insert deal;

    User plainInternalUser = TestUserFactory.createInternalUser();

    System.runAs(plainInternalUser) {
      InternalDashboardDTO dto = InternalDashboardService.getDashboard();

      System.assertEquals(
        0,
        dto.pendingDealReviewCount,
        'A user with no deal-review permission set should see zero, not an error.'
      );
      System.assertEquals(0, dto.pendingMdfReviewCount);
      System.assertEquals(0, dto.unreadNotificationCount);
      System.assertEquals(0, dto.alerts.size());
    }
  }
}
