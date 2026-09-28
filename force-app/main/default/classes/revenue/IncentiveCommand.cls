/**
 * Request payload shared by evaluate/calculate and the simple status
 * transitions on IncentiveCommandService.
 */
public class IncentiveCommand {
  public Id incentiveId;
  public Id revenueAttributionId;
  public String action;
  public Integer expectedVersion;
  public String reason;

  // Evaluate-only field - the doc's policy model keys a calculation type
  // by Incentive_Type__c, but nothing upstream of this command yet infers
  // one automatically, so the caller supplies it (defaults to 'Commission'
  // if blank).
  public String incentiveType;
}
