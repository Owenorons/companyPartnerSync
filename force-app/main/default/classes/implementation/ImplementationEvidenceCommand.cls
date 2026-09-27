/**
 * Request payload shared by submit/review on
 * ImplementationEvidenceCommandService.
 */
public class ImplementationEvidenceCommand {
  public Id evidenceId;
  public Id implementationId;
  public Id milestoneId;
  public String action;
  public String reason;

  // Submit-only fields.
  public String evidenceType;
  public String contentDocumentId;
  public String description;
  public Boolean partnerVisible;
  public Boolean customerVisible;

  // Review-only field.
  public String outcome;
}
