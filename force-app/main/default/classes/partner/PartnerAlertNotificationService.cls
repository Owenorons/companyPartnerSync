public without sharing class PartnerAlertNotificationService {
  @TestVisible
  private static Boolean testRouteEnabled;
  @TestVisible
  private static String testMinimumSeverity;
  @TestVisible
  private static Boolean testInAppEnabled;
  @TestVisible
  private static String testEmailRecipients;
  @TestVisible
  private static Integer testReminderHours;

  public static void notifyNewAlerts(Set<Id> alertIds) {
    if (alertIds == null || alertIds.isEmpty())
      return;
    RouteConfig route = loadRoute();
    if (!route.active)
      return;
    List<Partner_Operational_Alert__c> eligible = new List<Partner_Operational_Alert__c>();
    Datetime reminderCutoff = System.now().addHours(-route.reminderHours);
    for (Partner_Operational_Alert__c alert : [
      SELECT
        Id,
        Name,
        Alert_Type__c,
        Severity__c,
        Message__c,
        Notification_Status__c,
        Notified_On__c
      FROM Partner_Operational_Alert__c
      WHERE
        Id IN :alertIds
        AND (Notification_Status__c = 'Pending'
        OR Notified_On__c = NULL
        OR Notified_On__c <= :reminderCutoff)
      WITH SYSTEM_MODE
      FOR UPDATE
    ])
      if (meetsThreshold(alert.Severity__c, route.minimumSeverity))
        eligible.add(alert);
    if (eligible.isEmpty())
      return;
    List<Partner_Alert_Delivery_Attempt__c> attempts = new List<Partner_Alert_Delivery_Attempt__c>();
    Set<Id> deliveredAlertIds = new Set<Id>();
    if (route.inAppEnabled)
      deliveredAlertIds.addAll(
        createInAppNotifications(eligible, attempts, route.reminderHours)
      );
    deliveredAlertIds.addAll(
      sendEmails(eligible, route.emailRecipients, attempts, route.reminderHours)
    );
    if (attempts.isEmpty()) {
      for (Partner_Operational_Alert__c alert : eligible)
        attempts.add(
          newAttempt(
            alert.Id,
            'In-App',
            'No configured recipient',
            false,
            'No active in-app or email recipient is configured.',
            route.reminderHours,
            null
          )
        );
    }
    Datetime attemptedOn = System.now();
    for (Partner_Operational_Alert__c alert : eligible) {
      alert.Notification_Status__c = deliveredAlertIds.contains(alert.Id)
        ? 'Notified'
        : 'Failed';
      alert.Notified_On__c = attemptedOn;
    }
    Database.insert(attempts, AccessLevel.SYSTEM_MODE);
    Database.update(eligible, AccessLevel.SYSTEM_MODE);
  }

  private static Set<Id> createInAppNotifications(
    List<Partner_Operational_Alert__c> alerts,
    List<Partner_Alert_Delivery_Attempt__c> attempts,
    Integer reminderHours
  ) {
    Set<Id> recipientIds = new Set<Id>();
    for (PermissionSetAssignment assignment : [
      SELECT AssigneeId
      FROM PermissionSetAssignment
      WHERE
        PermissionSet.Name = 'PartnerSync_Operational_Alert_Manager'
        AND Assignee.IsActive = TRUE
      WITH SYSTEM_MODE
    ])
      recipientIds.add(assignment.AssigneeId);
    List<Partner_Notification__c> notifications = new List<Partner_Notification__c>();
    List<Id> notificationAlertIds = new List<Id>();
    for (Partner_Operational_Alert__c alert : alerts)
      for (Id recipientId : recipientIds) {
        notifications.add(
          new Partner_Notification__c(
            Recipient_User__c = recipientId,
            Notification_Type__c = 'System',
            Title__c = alert.Severity__c +
              ' operational alert: ' +
              alert.Alert_Type__c,
            Message__c = alert.Message__c,
            Priority__c = 'High',
            Related_Object__c = 'Partner_Operational_Alert__c',
            Related_Record_Id__c = alert.Id,
            Action_Label__c = 'Review alert',
            Action_URL__c = '/' + alert.Id,
            Is_Read__c = false,
            Dismissed__c = false
          )
        );
        notificationAlertIds.add(alert.Id);
      }
    Set<Id> delivered = new Set<Id>();
    if (notifications.isEmpty())
      return delivered;
    Database.SaveResult[] results = Database.insert(
      notifications,
      false,
      AccessLevel.SYSTEM_MODE
    );
    for (Integer index = 0; index < results.size(); index++) {
      Database.SaveResult result = results[index];
      Id alertId = notificationAlertIds[index];
      if (result.isSuccess())
        delivered.add(alertId);
      attempts.add(
        newAttempt(
          alertId,
          'In-App',
          String.valueOf(notifications[index].Recipient_User__c),
          result.isSuccess(),
          result.isSuccess() ? null : result.getErrors()[0].getMessage(),
          reminderHours,
          result.isSuccess() ? result.getId() : null
        )
      );
    }
    return delivered;
  }

  private static Set<Id> sendEmails(
    List<Partner_Operational_Alert__c> alerts,
    String recipients,
    List<Partner_Alert_Delivery_Attempt__c> attempts,
    Integer reminderHours
  ) {
    Set<Id> delivered = new Set<Id>();
    if (String.isBlank(recipients))
      return delivered;
    List<String> addresses = recipients.replace(';', ',').split(',');
    for (String rawAddress : addresses) {
      String address = rawAddress.trim();
      if (String.isBlank(address))
        continue;
      for (Partner_Operational_Alert__c alert : alerts) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new List<String>{ address });
        email.setSubject('PartnerSync critical alert: ' + alert.Alert_Type__c);
        email.setPlainTextBody(
          alert.Name + ' | ' + alert.Alert_Type__c + ' | ' + alert.Message__c
        );
        Messaging.SendEmailResult result = Messaging.sendEmail(
          new List<Messaging.SingleEmailMessage>{ email }
        )[0];
        if (result.isSuccess())
          delivered.add(alert.Id);
        attempts.add(
          newAttempt(
            alert.Id,
            'Email',
            address,
            result.isSuccess(),
            result.isSuccess() ? null : result.getErrors()[0].getMessage(),
            reminderHours,
            null
          )
        );
      }
    }
    return delivered;
  }

  private static Partner_Alert_Delivery_Attempt__c newAttempt(
    Id alertId,
    String channel,
    String recipient,
    Boolean succeeded,
    String errorDetail,
    Integer reminderHours,
    Id notificationId
  ) {
    Datetime attemptedOn = System.now();
    return new Partner_Alert_Delivery_Attempt__c(
      Alert__c = alertId,
      Channel__c = channel,
      Recipient__c = recipient,
      Status__c = succeeded ? 'Succeeded' : 'Failed',
      Attempted_On__c = attemptedOn,
      Error_Detail__c = errorDetail,
      Retry_On__c = succeeded ? null : attemptedOn.addHours(reminderHours),
      Notification_Id__c = notificationId == null
        ? null
        : String.valueOf(notificationId)
    );
  }

  private static Boolean meetsThreshold(
    String severity,
    String minimumSeverity
  ) {
    Map<String, Integer> rank = new Map<String, Integer>{
      'Medium' => 1,
      'High' => 2,
      'Critical' => 3
    };
    return rank.get(severity) >= rank.get(minimumSeverity);
  }

  private static RouteConfig loadRoute() {
    RouteConfig route = new RouteConfig();
    if (Test.isRunningTest() && testRouteEnabled != null) {
      route.active = testRouteEnabled;
      route.minimumSeverity = testMinimumSeverity;
      route.inAppEnabled = testInAppEnabled;
      route.emailRecipients = testEmailRecipients;
      route.reminderHours = testReminderHours == null ? 24 : testReminderHours;
      return route;
    }
    Operational_Alert_Route__mdt metadata = Operational_Alert_Route__mdt.getInstance(
      'Critical_Default'
    );
    route.active = metadata != null && metadata.Active__c;
    route.minimumSeverity = metadata == null
      ? 'Critical'
      : metadata.Minimum_Severity__c;
    route.inAppEnabled = metadata != null && metadata.In_App_Enabled__c;
    route.emailRecipients = metadata == null
      ? null
      : metadata.Email_Recipients__c;
    route.reminderHours = metadata == null ||
      metadata.Reminder_Hours__c == null
      ? 24
      : metadata.Reminder_Hours__c.intValue();
    return route;
  }

  private class RouteConfig {
    Boolean active;
    String minimumSeverity;
    Boolean inAppEnabled;
    String emailRecipients;
    Integer reminderHours;
  }
}
