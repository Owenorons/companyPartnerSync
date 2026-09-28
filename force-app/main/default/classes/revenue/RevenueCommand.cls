/**
 * Request payload shared by confirm/adjust/reverse on
 * RevenueCommandService.
 */
public class RevenueCommand {
  public Id revenueId;
  public String action;
  public Integer expectedVersion;
  public String reason;

  // Adjust-only fields.
  public Decimal newGrossAmount;
  public Decimal newNetAmount;
}
