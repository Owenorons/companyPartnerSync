/**
 * Aggregate KPI numbers for a single partner's dashboard summary tile
 * (leads, deals, revenue, MDF budget) — all pre-computed rates and totals,
 * not raw records.
 */
public with sharing class PartnerKPIDTO {
  /**
   * Total number of leads associated with the partner.
   */
  @AuraEnabled
  public Integer totalLeads { get; set; }
  /**
   * Number of leads accepted or subsequently converted by the partner.
   */
  @AuraEnabled
  public Integer acceptedLeads { get; set; }
  /**
   * Number of leads converted by the partner.
   */
  @AuraEnabled
  public Integer convertedLeads { get; set; }

  /**
   * Total number of deals associated with the partner.
   */
  @AuraEnabled
  public Integer totalDeals { get; set; }
  /**
   * Number of deals approved for the partner.
   */
  @AuraEnabled
  public Integer approvedDeals { get; set; }
  /**
   * Number of deals won by the partner.
   */
  @AuraEnabled
  public Integer wonDeals { get; set; }

  /**
   * Total open pipeline value for the partner.
   */
  @AuraEnabled
  public Decimal totalPipeline { get; set; }
  /**
   * Total won revenue for the partner.
   */
  @AuraEnabled
  public Decimal totalRevenue { get; set; }

  /**
   * Rate of leads accepted out of total leads.
   */
  @AuraEnabled
  public Decimal leadAcceptanceRate { get; set; }
  /**
   * Rate of leads converted out of total leads.
   */
  @AuraEnabled
  public Decimal leadConversionRate { get; set; }
  /**
   * Rate of won opportunities out of closed opportunities (won plus lost).
   */
  @AuraEnabled
  public Decimal dealWinRate { get; set; }

  /**
   * The partner's annual MDF budget.
   */
  @AuraEnabled
  public Decimal mdfAnnualBudget { get; set; }
  /**
   * Amount of MDF budget already used.
   */
  @AuraEnabled
  public Decimal mdfUsed { get; set; }
  /**
   * Amount of MDF budget remaining.
   */
  @AuraEnabled
  public Decimal mdfRemaining { get; set; }
  /**
   * Rate of MDF budget utilised.
   */
  @AuraEnabled
  public Decimal mdfUtilisationRate { get; set; }

  /**
   * Overall computed health score for the partner.
   */
  @AuraEnabled
  public Decimal healthScore { get; set; }
  /**
   * Human-readable label for the partner's health score.
   */
  @AuraEnabled
  public String healthLabel { get; set; }
  /**
   * Tier recommended for the partner based on current performance.
   */
  @AuraEnabled
  public String recommendedTier { get; set; }
  /**
   * List of signals contributing to the partner's health score.
   */
  @AuraEnabled
  public List<String> healthSignals { get; set; }
}
