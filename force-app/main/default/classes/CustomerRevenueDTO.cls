/*
 * Aggregated revenue row (customer x partner) surfaced to analytics
 * dashboards in the LWC layer. Purely a data-transfer shape; no behavior.
 */
public with sharing class CustomerRevenueDTO {
  @AuraEnabled
  public Id customerAccountId { get; set; }
  @AuraEnabled
  public String customerName { get; set; }

  @AuraEnabled
  public Id partnerAccountId { get; set; }
  @AuraEnabled
  public String partnerName { get; set; }

  @AuraEnabled
  public Decimal revenue { get; set; }
  @AuraEnabled
  public Integer opportunityCount { get; set; }
}
