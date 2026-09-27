/**
 * Request payload shared by create/start/complete/block/waive on
 * ImplementationMilestoneCommandService.
 */
public class ImplementationMilestoneCommand {
  public Id milestoneId;
  public Id implementationId;
  public String action;
  public Integer expectedVersion;
  public String reason;

  // Create-only fields.
  public String milestoneType;
  public String name;
  public Date dueOn;
  public Boolean required;
  public Boolean blocking;
}
