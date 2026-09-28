/**
 * Request payload shared by ExpansionCommandService's
 * identify/qualify/createExpansionDeal/complete.
 */
public class ExpansionCommand {
  public Id expansionId;
  public Integer expectedVersion;
  public Id customerSuccessEngagementId;
  public Id customerAccountId;
  public Id originatingDealId;
  public Id primaryPartnerId;
  public String expansionType;
  public String description;
  public Decimal estimatedPercentageIncrease;

  // createExpansionDeal-only fields.
  public String businessProblem;
  public String proposedSolution;
  public Decimal estimatedRevenue;
  public Date estimatedCloseDate;

  // complete-only field.
  public Decimal completedAmount;
}
