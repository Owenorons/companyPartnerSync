/**
 * Counts-only cross-domain "needs attention" summary, for
 * PartnerOperationsCommandCenterController. Never duplicates row-level
 * data the existing workbenches already show - see each field's own
 * workbench for detail.
 */
public class OperationsSummaryDTO {
  @AuraEnabled
  public Integer pendingHandoffCount;
  @AuraEnabled
  public Integer atRiskEngagementCount;
  @AuraEnabled
  public Integer renewalsDueCount;
  @AuraEnabled
  public Integer partnerConfirmationRequiredCount;
  @AuraEnabled
  public Integer openExpansionCount;
  @AuraEnabled
  public Integer pendingReassignmentCount;
  @AuraEnabled
  public Integer openDisputeCount;
  @AuraEnabled
  public Integer proposedRecommendationCount;
}
