/**
 * Internal request payload for NotificationService.create() — used by
 * other server-side services to raise a Partner_Notification__c, not
 * exposed directly to the LWC layer (contrast PartnerNotificationDTO, the
 * read-side DTO that is @AuraEnabled).
 */
public with sharing class NotificationRequestDTO {
  /**
   * Id of the partner account the notification relates to.
   */
  public Id partnerAccountId;

  /**
   * Id of the partner contact to notify, if applicable.
   */
  public Id recipientContactId;

  /**
   * Id of the internal user to notify, if applicable.
   */
  public Id recipientUserId;

  /**
   * Notification type/category (e.g. the originating business event).
   */
  public String notificationType;

  /**
   * Notification title.
   */
  public String title;

  /**
   * Notification body message.
   */
  public String message;

  /**
   * Label for the notification's optional call-to-action link.
   */
  public String actionLabel;

  /**
   * URL for the notification's optional call-to-action link.
   */
  public String actionUrl;

  /**
   * API name of the SObject this notification relates to, if any.
   */
  public String relatedObject;

  /**
   * Id of the specific record this notification relates to, if any.
   */
  public Id relatedRecordId;

  /**
   * Notification priority (e.g. Normal, High); defaults to Normal if blank.
   */
  public String priority;
}
