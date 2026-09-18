/**
 * Request payload for a deal review lifecycle command, describing the
 * target review, the action, and any outcome, assignment, or evidence
 * request details.
 */
public class DealReviewCommand {
  public Id reviewId;
  public String action;
  public String outcome;
  public String reason;
  public Id assigneeId;
  public String question;
  public String audience;
  public String evidenceRequirement;
  public Datetime dueOn;
  public Integer expectedVersion;
}
