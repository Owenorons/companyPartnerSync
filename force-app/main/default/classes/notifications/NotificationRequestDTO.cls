/*
 * Internal request payload for NotificationService.create() — used by
 * other server-side services to raise a Partner_Notification__c, not
 * exposed directly to the LWC layer (contrast PartnerNotificationDTO, the
 * read-side DTO that is @AuraEnabled).
 */
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
