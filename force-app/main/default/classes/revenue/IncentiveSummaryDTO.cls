/**
 * Partner-safe summary of a Partner_Incentive__c - excludes internal
 * calculation snapshots/rates that reveal the underlying policy
 * mechanics (doc §41.53).
 */
public class IncentiveSummaryDTO {
  @AuraEnabled
  public Id incentiveId;
  @AuraEnabled
  public Id dealId;
  @AuraEnabled
  public String incentiveType;
  @AuraEnabled
  public String status;
  @AuraEnabled
  public Decimal calculatedAmount;
  @AuraEnabled
  public Decimal approvedAmount;
  @AuraEnabled
  public Decimal paidAmount;
  @AuraEnabled
  public String currencyIsoCode;
  @AuraEnabled
  public Date eligibilityDate;
  @AuraEnabled
  public Date paymentDate;
}
