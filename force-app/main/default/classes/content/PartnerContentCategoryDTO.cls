/**
 * Label/value pair for a Partner_Content__c Category__c picklist entry,
 * sent to the LWC layer to populate category filter options.
 */
public with sharing class PartnerContentCategoryDTO {
  /**
   * Display label of the picklist entry.
   */
  @AuraEnabled
  public String label { get; set; }
  /**
   * API value of the picklist entry.
   */
  @AuraEnabled
  public String value { get; set; }
}
