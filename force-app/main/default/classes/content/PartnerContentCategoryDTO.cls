/*
 * Label/value pair for a Partner_Content__c Category__c picklist entry,
 * sent to the LWC layer to populate category filter options.
 */
public with sharing class PartnerContentCategoryDTO {
  @AuraEnabled
  public String label;
  @AuraEnabled
  public String value;
}
