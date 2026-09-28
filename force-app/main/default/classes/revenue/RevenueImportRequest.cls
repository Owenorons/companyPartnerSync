/**
 * Normalized revenue-import request passed to a RevenueSourceAdapter. Each
 * adapter builds one of these from its own source-specific input (a manual
 * form, an Opportunity) before RevenueCommandService.importRevenue()
 * resolves the Deal, checks idempotency, and inserts.
 */
public class RevenueImportRequest {
  public Id explicitDealId;
  public Id opportunityId;
  public Id implementationId;
  public String revenueType;
  public String sourceType;
  public Decimal grossAmount;
  public Decimal netAmount;
  public Decimal eligibleAmount;
  public String currencyIsoCode;
  public Date revenueDate;
  public String accountingPeriod;
  public Decimal quantity;
  public Decimal unitValue;
  public String sourceSystem;
  public String sourceRecordType;
  public String sourceRecordId;
  public String sourceTransactionId;
  public String sourceEventId;
  public Datetime sourceEffectiveOn;
  public String externalRevenueKey;
  public Decimal taxAmount;
  public Boolean taxInclusive;
}
