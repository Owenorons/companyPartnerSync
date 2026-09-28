/**
 * Request payload shared by RenewalCommandService's
 * confirmParticipation/declineParticipation/qualify/requestReview/approve/
 * markRenewed/markNotRenewed.
 */
public class RenewalCommand {
  public Id renewalId;
  public Integer expectedVersion;
  public String reason;
  public Id currentOpportunityId;
  public Id currentDealId;
  public Decimal renewedAmount;
  public String currencyIsoCode;
}
