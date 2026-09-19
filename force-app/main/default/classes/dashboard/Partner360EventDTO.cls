/**
 * DTO representing a single lifecycle event shown in a partner's Partner 360
 * recent-activity timeline.
 */
public with sharing class Partner360EventDTO {
  /**
   * Id of the underlying record the event relates to.
   */
  @AuraEnabled
  public Id recordId { get; set; }
  /**
   * Type of the event.
   */
  @AuraEnabled
  public String eventType { get; set; }
  /**
   * Onboarding/lifecycle stage the event occurred in.
   */
  @AuraEnabled
  public String stage { get; set; }
  /**
   * Human-readable summary of the event.
   */
  @AuraEnabled
  public String summary { get; set; }
  /**
   * Date/time the event occurred.
   */
  @AuraEnabled
  public Datetime occurredOn { get; set; }
}
