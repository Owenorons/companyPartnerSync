/**
 * Request payload shared by open/resolve on RevenueDisputeCommandService.
 */
public class RevenueDisputeCommand {
  public Id disputeId;
  public Id partnerAccountId;
  public Id dealId;
  public Id revenueId;
  public Id revenueAttributionId;
  public Id incentiveId;
  public String disputeType;
  public String description;
  public String requestedAdjustment;
  public String resolution;
}
