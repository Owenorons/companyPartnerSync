/**
 * Request payload shared by overrideAttribution/reverseAttribution on
 * RevenueAttributionCommandService.
 */
public class RevenueAttributionCommand {
  public Id attributionId;
  public Integer expectedVersion;
  public String reason;

  // Override-only field.
  public Decimal newAttributionPercentage;
}
