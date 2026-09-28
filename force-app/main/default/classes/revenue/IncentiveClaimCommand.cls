/**
 * Request payload shared by submit/approve/reject on
 * IncentiveClaimCommandService.
 */
public class IncentiveClaimCommand {
  public Id claimId;
  public Id incentiveId;
  public String action;
  public Integer expectedVersion;
  public String reason;

  // Submit-only fields.
  public Decimal claimedAmount;
  public String claimReason;
}
