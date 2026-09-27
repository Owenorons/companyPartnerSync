/**
 * Request payload shared by request/record/reject on
 * ImplementationAcceptanceCommandService.
 */
public class ImplementationAcceptanceCommand {
  public Id acceptanceId;
  public Id implementationId;
  public String action;
  public Integer expectedVersion;
  public String reason;

  // Request-only fields.
  public String acceptanceType;
  public Id customerContactId;

  // Record-only fields.
  public String acceptedByName;
  public String acceptedByEmail;
}
