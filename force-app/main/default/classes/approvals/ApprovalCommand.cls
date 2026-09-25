/**
 * Request payload for an approval decision command, describing the target
 * approval, the decision, and any conditional-approval details.
 */
public class ApprovalCommand {
  public Id approvalId;
  public String decision;
  public String reason;
  public Integer expectedVersion;
  public String conditionType;
  public String conditionDescription;
}
