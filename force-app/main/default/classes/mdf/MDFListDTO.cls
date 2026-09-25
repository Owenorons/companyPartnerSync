/**
 * DTO for a single MDF request row, used by both the partner's "my
 * requests" list and the internal review queue.
 */
public with sharing class MDFListDTO {
  /**
   * Id of the underlying MDF_Request__c record.
   */
  @AuraEnabled
  public Id requestId { get; set; }

  /**
   * Display name/number of the MDF request record.
   */
  @AuraEnabled
  public String requestNumber { get; set; }

  /**
   * Name of the partner account that submitted the request.
   */
  @AuraEnabled
  public String partnerName { get; set; }

  /**
   * Name of the campaign the MDF request is for.
   */
  @AuraEnabled
  public String campaignName { get; set; }

  /**
   * Type of MDF request (e.g. campaign type/category).
   */
  @AuraEnabled
  public String requestType { get; set; }

  /**
   * Amount originally requested by the partner.
   */
  @AuraEnabled
  public Decimal requestedAmount { get; set; }

  /**
   * Amount approved by an internal reviewer, if decided.
   */
  @AuraEnabled
  public Decimal approvedAmount { get; set; }

  /**
   * Eligible funding ceiling computed from the tenant's industry-scoped MDF
   * calculation rules. Null if no rule matched - informational only.
   */
  @AuraEnabled
  public Decimal eligibleAmount { get; set; }

  /**
   * Current status of the MDF request (e.g. Submitted, Under Review,
   * Approved, Rejected).
   */
  @AuraEnabled
  public String status { get; set; }

  /**
   * Reason a pre-approval chain step sent this request back for correction. Only set while
   * status is Needs Information.
   */
  @AuraEnabled
  public String returnReason { get; set; }

  /**
   * Planned start date of the funded activity.
   */
  @AuraEnabled
  public Date startDate { get; set; }

  /**
   * Planned end date of the funded activity.
   */
  @AuraEnabled
  public Date endDate { get; set; }
}
