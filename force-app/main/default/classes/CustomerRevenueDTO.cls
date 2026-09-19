/**
 * Aggregated revenue row (customer x partner) surfaced to analytics
 * dashboards in the LWC layer. Purely a data-transfer shape; no behavior.
 */
public with sharing class CustomerRevenueDTO {
  /** The Id of the customer account this revenue row is for. */
  @AuraEnabled
  public Id customerAccountId { get; set; }
  /** The name of the customer account this revenue row is for. */
  @AuraEnabled
  public String customerName { get; set; }

  /** The Id of the sourcing partner account for this revenue row. */
  @AuraEnabled
  public Id partnerAccountId { get; set; }
  /** The name of the sourcing partner account for this revenue row. */
  @AuraEnabled
  public String partnerName { get; set; }

  /** The total closed-won revenue for this customer/partner pairing. */
  @AuraEnabled
  public Decimal revenue { get; set; }
  /** The number of closed-won opportunities for this customer/partner pairing. */
  @AuraEnabled
  public Integer opportunityCount { get; set; }
}
