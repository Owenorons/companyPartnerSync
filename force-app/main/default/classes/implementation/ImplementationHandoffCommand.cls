/**
 * Request payload shared by submit/accept/return on
 * ImplementationHandoffCommandService.
 */
public class ImplementationHandoffCommand {
  public Id implementationId;
  public Id handoffId;
  public String action;
  public Integer expectedVersion;
  public String reason;

  // Submit-only fields.
  public Id salesOwnerId;
  public Id deliveryOwnerId;
  public String customerObjectives;
  public String solutionSummary;
  public String commercialSummary;
  public String scopeSummary;
  public String keyAssumptions;
  public String knownRisks;
  public String dependencies;
  public Date targetStartDate;
  public Date targetCompletionDate;
  public Boolean requiredEvidenceComplete;
}
