/**
 * One row of the partner leaderboard view — pre-aggregated performance
 * numbers for a single partner account, ready for direct display without
 * further client-side computation.
 */
public with sharing class PartnerLeaderboardRowDTO {
  /**
   * Id of the partner Account this row summarizes.
   */
  @AuraEnabled
  public Id partnerAccountId { get; set; }
  /**
   * Name of the partner Account.
   */
  @AuraEnabled
  public String partnerName { get; set; }
  /**
   * The partner's current tier.
   */
  @AuraEnabled
  public String partnerTier { get; set; }
  /**
   * The partner's current status.
   */
  @AuraEnabled
  public String partnerStatus { get; set; }

  /**
   * Count of leads accepted by the partner.
   */
  @AuraEnabled
  public Integer acceptedLeads { get; set; }
  /**
   * Count of deals approved for the partner.
   */
  @AuraEnabled
  public Integer approvedDeals { get; set; }
  /**
   * Count of deals won by the partner.
   */
  @AuraEnabled
  public Integer wonDeals { get; set; }

  /**
   * Total revenue attributed to the partner.
   */
  @AuraEnabled
  public Decimal revenue { get; set; }
  /**
   * The partner's lead-to-deal conversion rate.
   */
  @AuraEnabled
  public Decimal conversionRate { get; set; }
  /**
   * The partner's overall leaderboard score.
   */
  @AuraEnabled
  public Decimal score { get; set; }
}
