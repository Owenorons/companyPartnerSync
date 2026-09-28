/**
 * Request payload shared by PartnerReassignmentCommandService's
 * request/approve.
 */
public class PartnerReassignmentCommand {
  public Id reassignmentId;
  public Integer expectedVersion;
  public String targetObject;
  public Id targetRecordId;
  public Id requestedPartnerId;
  public String reason;
}
