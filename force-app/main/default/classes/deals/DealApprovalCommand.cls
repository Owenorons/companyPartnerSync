/**
 * Request payload for a deal approval decision command, describing the
 * target approval, the decision, and any conditional-approval details.
 */
public class DealApprovalCommand {
  public Id approvalId;
  public String decision;
  public String reason;
  public Integer expectedVersion;
  public String conditionType;
  public String conditionDescription;
}
