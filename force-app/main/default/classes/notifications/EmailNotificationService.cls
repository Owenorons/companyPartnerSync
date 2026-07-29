/*
 * Thin wrapper around Messaging.SingleEmailMessage for outbound partner
 * emails. Separate from the in-app Partner_Notification__c pipeline
 * (NotificationService/NotificationQueryService) — this only sends email,
 * it does not read or write notification records.
 */
public with sharing class EmailNotificationService {
  public static void sendNotification(
    String toAddress,
    String subject,
    String body
  ) {
    // A blank address is a silent no-op rather than an error: callers may
    // invoke this for partner contacts that have no email on file, and that
    // should not block whatever business action triggered the notification.
    if (String.isBlank(toAddress)) {
      return;
    }

    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

    email.setToAddresses(new List<String>{ toAddress });

    email.setSubject(subject);

    email.setPlainTextBody(body);

    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
  }
}
