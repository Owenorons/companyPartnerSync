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

  @IsTest
  static void authorisedManagerAcknowledgesAlert() {
    Datetime detected = System.now();
    Partner_Operational_Alert__c alert = new Partner_Operational_Alert__c(
      Alert_Key__c = 'CONTROLLER:ACK',
      Alert_Type__c = 'Overdue Work',
      Severity__c = 'High',
      Status__c = 'Open',
      Source_Record_Id__c = UserInfo.getUserId(),
      Message__c = 'Acknowledge me.',
      Occurrence_Count__c = 1,
      First_Detected_On__c = detected,
      Last_Detected_On__c = detected
    );
    insert alert;
    User manager = TestUserFactory.createInternalUser();
    TestUserFactory.assignPermissionSet(
      manager.Id,
      'PartnerSync_Operational_Alert_Manager'
    );
    System.runAs(manager) {
      InternalPortalController.acknowledgeOperationalAlert(alert.Id);
      InternalPortalController.transitionOperationalAlert(alert.Id, 'resolve');
      InternalPortalController.transitionOperationalAlert(alert.Id, 'reopen');
    }
    alert = [
      SELECT
        Status__c,
        Acknowledged_By__c,
        Resolved_By__c,
        Resolved_On__c,
        Reopened_By__c,
        Reopened_On__c,
        Notification_Status__c
      FROM Partner_Operational_Alert__c
      WHERE Id = :alert.Id
    ];
    System.assertEquals('Open', alert.Status__c);
    System.assertEquals(manager.Id, alert.Acknowledged_By__c);
    System.assertEquals(manager.Id, alert.Resolved_By__c);
    System.assertNotEquals(null, alert.Resolved_On__c);
    System.assertEquals(manager.Id, alert.Reopened_By__c);
    System.assertNotEquals(null, alert.Reopened_On__c);
    System.assertEquals('Pending', alert.Notification_Status__c);
  }

  @IsTest
  static void unexpectedDashboardFailureIsHandled() {
    InternalPortalController.testDashboardFailure = true;
    try {
      InternalPortalController.getDashboard();
      System.assert(false, 'Expected handled dashboard error.');
    } catch (AuraHandledException expected) {
      System.assertNotEquals(null, expected);
    }
  }

  @IsTest
  static void acknowledgementWithoutAuthorityIsHandled() {
    Datetime detected = System.now();
    Partner_Operational_Alert__c alert = new Partner_Operational_Alert__c(
      Alert_Key__c = 'CONTROLLER:DENIED',
      Alert_Type__c = 'Overdue Work',
      Severity__c = 'High',
      Status__c = 'Open',
      Source_Record_Id__c = UserInfo.getUserId(),
      Message__c = 'Denied.',
      Occurrence_Count__c = 1,
      First_Detected_On__c = detected,
      Last_Detected_On__c = detected
    );
    insert alert;
    User internalUser = TestUserFactory.createInternalUser();
    System.runAs(internalUser) {
      try {
        InternalPortalController.acknowledgeOperationalAlert(alert.Id);
        System.assert(false, 'Expected handled authority error.');
      } catch (AuraHandledException expected) {
        System.assertNotEquals(null, expected);
      }
    }
  }
}
