/**
 * Request payload shared by assign/remove on
 * ImplementationParticipantCommandService.
 */
public class ImplementationParticipantCommand {
  public Id implementationParticipantId;
  public Id implementationId;
  public Id dealParticipantId;
  public String role;
  public Boolean primary;
  public String responsibilitySummary;
}
