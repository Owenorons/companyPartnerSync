/**
 * Row shape for one partner-visible lifecycle event on the deal detail
 * timeline (DealRegistrationDetailDTO.events).
 */
public with sharing class DealTimelineEventDTO {
  /**
   * The event's business type (e.g. Submitted, UnderReview, Approved).
   */
  @AuraEnabled
  public String eventType { get; set; }

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
