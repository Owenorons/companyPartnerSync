/**
 * Request payload shared by CustomerSuccessMilestoneCommandService's
 * create/complete/skip.
 */
public class CustomerSuccessMilestoneCommand {
  public Id milestoneId;
  public Id engagementId;
  public String milestoneType;
  public Date targetOn;
  public String notes;
}
