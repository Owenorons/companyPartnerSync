/**
 * Request payload shared by CustomerSuccessRiskCommandService's
 * raise/resolve/accept.
 */
public class CustomerSuccessRiskCommand {
  public Id riskId;
  public Id engagementId;
  public String riskType;
  public String severity;
  public String description;
  public String resolution;
  public String reason;
}
