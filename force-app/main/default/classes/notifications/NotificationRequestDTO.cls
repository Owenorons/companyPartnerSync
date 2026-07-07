public with sharing class NotificationRequestDTO {
  public Id partnerAccountId;

  public Id recipientContactId;

  public Id recipientUserId;

  public String notificationType;

  public String title;

  public String message;

  public String actionLabel;

  public String actionUrl;

  public String relatedObject;

  public Id relatedRecordId;

  public String priority;
}
