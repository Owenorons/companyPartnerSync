/*
 * Read-model DTO for a single in-app notification, exposed to the LWC layer
 * via NotificationQueryService. Contrast NotificationRequestDTO, the
 * internal write-side payload used to create these records in the first
 * place.
 */
public with sharing class PartnerNotificationDTO {
  @AuraEnabled
  public Id notificationId { get; set; }

  @AuraEnabled
  public String title { get; set; }

  @AuraEnabled
  public String message { get; set; }

  @AuraEnabled
  public String actionLabel { get; set; }

  @AuraEnabled
  public String actionUrl { get; set; }

  @AuraEnabled
  public String priority { get; set; }

  @AuraEnabled
  public Boolean isRead { get; set; }

  @AuraEnabled
  public Datetime createdDate { get; set; }
}
