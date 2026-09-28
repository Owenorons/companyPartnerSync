/**
 * Request payload shared by CommercialEntitlementCommandService's
 * record/renew/cancel.
 */
public class CommercialEntitlementCommand {
  public Id entitlementId;
  public Id customerAccountId;
  public Id customerSuccessEngagementId;
  public Id originatingDealId;
  public Id originatingOpportunityId;
  public Integer expectedVersion;

  public String product;
  public String productFamily;
  public String entitlementType;
  public Date effectiveStartOn;
  public Date effectiveEndOn;
  public Decimal quantity;
  public Boolean autoRenew;
  public Integer renewalNoticeDays;
  public Integer cancellationNoticeDays;
  public String externalContractId;
  public String externalSubscriptionId;

  public String reason;
}
