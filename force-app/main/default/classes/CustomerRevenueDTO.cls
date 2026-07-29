/*
 * Aggregated revenue row (customer x partner) surfaced to analytics
 * dashboards in the LWC layer. Purely a data-transfer shape; no behavior.
 */
public with sharing class CustomerRevenueDTO {
  @AuraEnabled
  public Id customerAccountId;
  @AuraEnabled
  public String customerName;

  @AuraEnabled
  public Id partnerAccountId;
  @AuraEnabled
  public String partnerName;

  @AuraEnabled
  public Decimal revenue;
  @AuraEnabled
  public Integer opportunityCount;
}
