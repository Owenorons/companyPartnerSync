public with sharing class EmailNotificationService {
  public static void sendNotification(
    String toAddress,
    String subject,
    String body
  ) {
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
