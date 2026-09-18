/**
 * Read-model DTO for a single in-app notification, exposed to the LWC layer
 * via NotificationQueryService. Contrast NotificationRequestDTO, the
 * internal write-side payload used to create these records in the first
 * place.
 */
public with sharing class PartnerNotificationDTO {
  /**
   * Id of the underlying Partner_Notification__c record.
   */
  @AuraEnabled
  public Id notificationId { get; set; }

  /**
   * Notification title.
   */
  @AuraEnabled
  public String title { get; set; }

  /**
   * Notification body message.
   */
  @AuraEnabled
  public String message { get; set; }

  /**
   * Label for the notification's optional call-to-action link.
   */
  @AuraEnabled
  public String actionLabel { get; set; }

  /**
   * URL for the notification's optional call-to-action link.
   */
  @AuraEnabled
  public String actionUrl { get; set; }

  /**
   * Priority of the notification (e.g. Normal, High).
   */
  @AuraEnabled
  public String priority { get; set; }

  /**
   * Whether the running user has marked this notification as read.
   */
  @AuraEnabled
  public Boolean isRead { get; set; }

  /**
   * When the notification was created.
   */
  @AuraEnabled
  public Datetime createdDate { get; set; }
}
