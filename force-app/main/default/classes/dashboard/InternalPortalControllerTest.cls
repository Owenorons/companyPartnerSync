/*
 * Verifies InternalPortalController's access boundary: an internal user
 * gets a dashboard back, while an external (partner) user is blocked with
 * a handled exception rather than an unhandled error.
 */
@IsTest
private class InternalPortalControllerTest {
  @IsTest
  static void internalUserGetsDashboardThroughController() {
    User internalUser = TestUserFactory.createInternalUser();

    System.runAs(internalUser) {
      InternalDashboardDTO dto = InternalPortalController.getDashboard();

      System.assertEquals(0, dto.pendingDealReviewCount);
      System.assertEquals(0, dto.pendingMdfReviewCount);
    }
  }

  @IsTest
  static void partnerUserIsBlockedWithHandledError() {
    Account partner = PartnerSyncTestDataFactory.partnerAccount('Partner');
    insert partner;

    Contact contact = PartnerSyncTestDataFactory.partnerContact(partner.Id);
    insert contact;

    User partnerUser = TestUserFactory.createExternalUser(contact.Id);

    System.runAs(partnerUser) {
      Boolean threw = false;

      try {
        InternalPortalController.getDashboard();
      } catch (AuraHandledException ex) {
        threw = true;
      }

      System.assertEquals(
        true,
        threw,
        'A partner (external) user should not be able to load the internal dashboard.'
      );
    }
  }
}
