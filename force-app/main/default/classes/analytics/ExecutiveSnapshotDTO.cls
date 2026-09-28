/**
 * Sanitized shape of an Executive_Snapshot__c, for
 * ExecutiveCommandCenterController.
 */
public class ExecutiveSnapshotDTO {
  @AuraEnabled
  public Id snapshotId;
  @AuraEnabled
  public Date snapshotDate;
  @AuraEnabled
  public Integer activePartnerCount;
  @AuraEnabled
  public Decimal averageHealthScore;
  @AuraEnabled
  public Integer totalOpenDealCount;
  @AuraEnabled
  public Integer totalAtRiskDealCount;
  @AuraEnabled
  public Integer totalActiveEngagementCount;
  @AuraEnabled
  public Integer totalAtRiskEngagementCount;
  @AuraEnabled
  public Integer totalUpcomingRenewalCount;
  @AuraEnabled
  public Decimal totalRenewalValueAtRisk;
  @AuraEnabled
  public Integer totalOpenExpansionCount;
  @AuraEnabled
  public Integer totalChurnedEngagementCountTrailing12mo;
  @AuraEnabled
  public Decimal totalRevenueTrailing12mo;
  @AuraEnabled
  public Integer openAiRecommendationCount;
  @AuraEnabled
  public String narrative;
  @AuraEnabled
  public Datetime computedOn;
}
