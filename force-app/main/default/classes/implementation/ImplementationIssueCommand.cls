/**
 * Request payload shared by raise/escalate/resolve/acceptRisk on
 * ImplementationIssueCommandService.
 */
public class ImplementationIssueCommand {
  public Id issueId;
  public Id implementationId;
  public Id milestoneId;
  public String action;
  public String reason;

  // Raise-only fields.
  public String issueType;
  public String severity;
  public String title;
  public String description;
  public Id ownerId;
  public Id partnerAccountId;
  public Boolean customerImpact;
  public Boolean commercialImpact;

  // Resolve-only field.
  public String resolution;
}
