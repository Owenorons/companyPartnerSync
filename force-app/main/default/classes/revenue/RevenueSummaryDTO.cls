/**
 * Partner-safe summary of a deal's revenue - no Gross_Amount__c/margin/
 * internal calculation snapshots (doc Sprint 41 §41.53). Access is
 * mediated entirely through RevenueController's own checks, not
 * PartnerShareService (Known Adaptation #8 - no sharing extension for
 * this domain).
 */
public class RevenueSummaryDTO {
  @AuraEnabled
  public Id revenueId;
  @AuraEnabled
  public Id dealId;
  @AuraEnabled
  public String revenueType;
  @AuraEnabled
  public String status;
  @AuraEnabled
  public Decimal netAmount;
  @AuraEnabled
  public String currencyIsoCode;
  @AuraEnabled
  public Date revenueDate;
  @AuraEnabled
  public String attributionType;
  @AuraEnabled
  public Decimal attributionPercentage;
  @AuraEnabled
  public Decimal attributedAmount;
}
