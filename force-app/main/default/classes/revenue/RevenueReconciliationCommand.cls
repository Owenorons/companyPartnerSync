/**
 * Request payload for RevenueReconciliationCommandService.resolve().
 */
public class RevenueReconciliationCommand {
  public Id reconciliationId;
  public Id candidateDealId;
  public String resolution;
  public String resolutionReason;
}
