/**
 * Request payload shared by CustomerSuccessCommandService's
 * createEngagement/acceptHandoff/recordChurn/reopenEngagement.
 */
public class CustomerSuccessCommand {
  public Id engagementId;
  public Id dealId;
  public Integer expectedVersion;
  public Id internalOwnerId;
  public Id partnerSuccessOwnerId;
  public String reason;
  public String churnCategory;
  public String churnNotes;
}
