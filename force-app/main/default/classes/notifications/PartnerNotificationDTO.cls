/*
 * Read-model DTO for a single in-app notification, exposed to the LWC layer
 * via NotificationQueryService. Contrast NotificationRequestDTO, the
 * internal write-side payload used to create these records in the first
 * place.
 */
public with sharing class PartnerNotificationDTO {
  @AuraEnabled
  public Id notificationId;

  @AuraEnabled
  public String title;

  @AuraEnabled
  public String message;

  @AuraEnabled
  public String actionLabel;

  @AuraEnabled
  public String actionUrl;

  @AuraEnabled
  public String priority;

  @AuraEnabled
  public Boolean isRead;

  @AuraEnabled
  public Datetime createdDate;
}
