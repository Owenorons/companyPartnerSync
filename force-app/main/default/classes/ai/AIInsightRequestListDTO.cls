/**
 * Row shape for an AI_Insight_Request__c: the partner-facing "requested"
 * list and the internal governance console's pending-requests queue.
 */
public with sharing class AIInsightRequestListDTO {
  /**
   * Id of the underlying AI_Insight_Request__c record.
   */
  @AuraEnabled
  public Id requestId { get; set; }

  /**
   * Id of the partner Account the request is for.
   */
  @AuraEnabled
  public Id partnerAccountId { get; set; }

  /**
   * Name of the partner Account the request is for. Only populated for
   * the internal queue, which spans many partners.
   */
  @AuraEnabled
  public String partnerName { get; set; }

  /**
   * DeveloperName of the requested AI_Feature_Config__mdt, for
   * pre-filling the generate form.
   */
  @AuraEnabled
  public String insightType { get; set; }

  /**
   * Display label of the requested insight type.
   */
  @AuraEnabled
  public String insightTypeLabel { get; set; }

  /**
   * The requester's free-text context for the request.
   */
  @AuraEnabled
  public String notes { get; set; }

  /**
   * Status of the request (New, Actioned, Dismissed).
   */
  @AuraEnabled
  public String status { get; set; }

  /**
   * Date/time the request was submitted.
   */
  @AuraEnabled
  public Datetime requestedOn { get; set; }
}
