/**
 * DTO carrying a partner's new MDF request from the LWC layer into
 * MDFService/MDFDomain for validation and record creation.
 */
public with sharing class MDFRequestDTO {
  /**
   * Type of MDF request being submitted (e.g. campaign type/category).
   */
  @AuraEnabled
  public String requestType { get; set; }
  /**
   * Name of the campaign the funds are requested for.
   */
  @AuraEnabled
  public String campaignName { get; set; }
  /**
   * Free-text description of the planned campaign activity.
   */
  @AuraEnabled
  public String campaignDescription { get; set; }
  /**
   * Amount of funding being requested.
   */
  @AuraEnabled
  public Decimal requestedAmount { get; set; }
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
  /**
   * Id of a related Deal record, if this request is tied to one.
   */
  @AuraEnabled
  public Id relatedDealId { get; set; }
  /**
   * Partner's committed outcome target; mapped to Expected_Leads__c on
   * the MDF_Request__c record since lead volume is the only ROI metric
   * currently tracked.
   */
  @AuraEnabled
  public Decimal roiTarget { get; set; }
}
