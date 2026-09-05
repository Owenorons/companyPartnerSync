@IsTest
private class PartnerAlertNotificationServiceTest {
  @TestSetup
  static void setupManager() {
    User manager = TestUserFactory.createInternalUser();
    manager.Alias = 'opalert';
    update manager;
    TestUserFactory.assignPermissionSet(
      manager.Id,
      'PartnerSync_Operational_Alert_Manager'
    );
  }

  private static Partner_Operational_Alert__c createAlert(
    String key,
    String severity
  ) {
    Datetime detected = System.now();
    Partner_Operational_Alert__c alert = new Partner_Operational_Alert__c(
      Alert_Key__c = key,
      Alert_Type__c = 'Scheduled Job Failure',
      Severity__c = severity,
      Status__c = 'Open',
      Source_Record_Id__c = UserInfo.getUserId(),
      Message__c = 'Job failed.',
      Occurrence_Count__c = 1,
      First_Detected_On__c = detected,
      Last_Detected_On__c = detected
    );
    insert alert;
    return alert;
  }

  @IsTest
  static void criticalRouteCreatesInAppAndEmailOnce() {
    Partner_Operational_Alert__c alert = createAlert(
      'ROUTE:CRITICAL',
      'Critical'
    );
    PartnerAlertNotificationService.testRouteEnabled = true;
    PartnerAlertNotificationService.testMinimumSeverity = 'Critical';
    PartnerAlertNotificationService.testInAppEnabled = true;
    PartnerAlertNotificationService.testEmailRecipients = 'ops1@example.test; ops2@example.test';
    Test.startTest();
    PartnerAlertNotificationService.notifyNewAlerts(new Set<Id>{ alert.Id });
    PartnerAlertNotificationService.notifyNewAlerts(new Set<Id>{ alert.Id });
    Integer emailInvocations = Limits.getEmailInvocations();
    Test.stopTest();
    alert = [
      SELECT Notification_Status__c, Notified_On__c
      FROM Partner_Operational_Alert__c
      WHERE Id = :alert.Id
    ];
    System.assertEquals('Notified', alert.Notification_Status__c);
    System.assertNotEquals(null, alert.Notified_On__c);
    System.assertEquals(2, emailInvocations);
    List<Partner_Notification__c> notifications = [
      SELECT
        Recipient_User__r.Alias,
        Notification_Type__c,
        Priority__c,
        Related_Record_Id__c
      FROM Partner_Notification__c
      WHERE Related_Record_Id__c = :alert.Id
    ];
    System.assertEquals(1, notifications.size());
    System.assertEquals('opalert', notifications[0].Recipient_User__r.Alias);
    System.assertEquals('System', notifications[0].Notification_Type__c);
    System.assertEquals(
      3,
      [
        SELECT COUNT()
        FROM Partner_Alert_Delivery_Attempt__c
        WHERE Alert__c = :alert.Id AND Status__c = 'Succeeded'
      ]
    );

    alert.Notified_On__c = System.now().addHours(-25);
    update alert;
    PartnerAlertNotificationService.testReminderHours = 24;
    PartnerAlertNotificationService.testEmailRecipients = null;
    PartnerAlertNotificationService.notifyNewAlerts(new Set<Id>{ alert.Id });
    System.assertEquals(
      2,
      [
        SELECT COUNT()
        FROM Partner_Notification__c
        WHERE Related_Record_Id__c = :alert.Id
      ]
    );
    System.assertEquals(
      4,
      [
        SELECT COUNT()
        FROM Partner_Alert_Delivery_Attempt__c
        WHERE Alert__c = :alert.Id
      ]
    );
  }

  @IsTest
  static void severityThresholdAndDisabledRouteDoNotDeliver() {
    Partner_Operational_Alert__c highAlert = createAlert('ROUTE:HIGH', 'High');
    PartnerAlertNotificationService.testRouteEnabled = true;
    PartnerAlertNotificationService.testMinimumSeverity = 'Critical';
    PartnerAlertNotificationService.testInAppEnabled = true;
    PartnerAlertNotificationService.notifyNewAlerts(
      new Set<Id>{ highAlert.Id }
    );
    highAlert = [
      SELECT Notification_Status__c
      FROM Partner_Operational_Alert__c
      WHERE Id = :highAlert.Id
    ];
    System.assertEquals('Pending', highAlert.Notification_Status__c);
    PartnerAlertNotificationService.testRouteEnabled = false;
    PartnerAlertNotificationService.notifyNewAlerts(
      new Set<Id>{ highAlert.Id }
    );
    System.assertEquals(
      0,
      [
        SELECT COUNT()
        FROM Partner_Notification__c
        WHERE Related_Record_Id__c = :highAlert.Id
      ]
    );
  }

  @IsTest
  static void emptyInputIsSafe() {
    Integer startingDml = Limits.getDmlStatements();
    PartnerAlertNotificationService.notifyNewAlerts(null);
    PartnerAlertNotificationService.notifyNewAlerts(new Set<Id>());
    System.assertEquals(startingDml, Limits.getDmlStatements());
  }

  @IsTest
  static void missingRecipientsCreateFailedAttemptAndRetry() {
    Partner_Operational_Alert__c alert = createAlert(
      'ROUTE:NO-RECIPIENT',
      'Critical'
    );
    PartnerAlertNotificationService.testRouteEnabled = true;
    PartnerAlertNotificationService.testMinimumSeverity = 'Critical';
    PartnerAlertNotificationService.testInAppEnabled = false;
    PartnerAlertNotificationService.testEmailRecipients = null;
    PartnerAlertNotificationService.testReminderHours = 12;
    PartnerAlertNotificationService.notifyNewAlerts(new Set<Id>{ alert.Id });
    alert = [
      SELECT Notification_Status__c
      FROM Partner_Operational_Alert__c
      WHERE Id = :alert.Id
    ];
    Partner_Alert_Delivery_Attempt__c attempt = [
      SELECT Status__c, Error_Detail__c, Attempted_On__c, Retry_On__c
      FROM Partner_Alert_Delivery_Attempt__c
      WHERE Alert__c = :alert.Id
      LIMIT 1
    ];
    System.assertEquals('Failed', alert.Notification_Status__c);
    System.assertEquals('Failed', attempt.Status__c);
    System.assert(attempt.Error_Detail__c.contains('No active'));
    System.assertEquals(
      attempt.Attempted_On__c.addHours(12),
      attempt.Retry_On__c
    );
  }
}
