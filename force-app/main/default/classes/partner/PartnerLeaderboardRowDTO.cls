/*
 * One row of the partner leaderboard view — pre-aggregated performance
 * numbers for a single partner account, ready for direct display without
 * further client-side computation.
 */
public with sharing class PartnerLeaderboardRowDTO {
  @AuraEnabled
  public Id partnerAccountId { get; set; }
  @AuraEnabled
  public String partnerName { get; set; }
  @AuraEnabled
  public String partnerTier { get; set; }
  @AuraEnabled
  public String partnerStatus { get; set; }

  @AuraEnabled
  public Integer acceptedLeads { get; set; }
  @AuraEnabled
  public Integer approvedDeals { get; set; }
  @AuraEnabled
  public Integer wonDeals { get; set; }

  @AuraEnabled
  public Decimal revenue { get; set; }
  @AuraEnabled
  public Decimal conversionRate { get; set; }
  @AuraEnabled
  public Decimal score { get; set; }
}
