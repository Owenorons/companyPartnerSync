/*
 * Aggregate KPI numbers for a single partner's dashboard summary tile
 * (leads, deals, revenue, MDF budget) — all pre-computed rates and totals,
 * not raw records.
 */
public with sharing class PartnerKPIDTO {
  @AuraEnabled
  public Integer totalLeads { get; set; }
  @AuraEnabled
  public Integer acceptedLeads { get; set; }
  @AuraEnabled
  public Integer convertedLeads { get; set; }

  @AuraEnabled
  public Integer totalDeals { get; set; }
  @AuraEnabled
  public Integer approvedDeals { get; set; }
  @AuraEnabled
  public Integer wonDeals { get; set; }

  @AuraEnabled
  public Decimal totalPipeline { get; set; }
  @AuraEnabled
  public Decimal totalRevenue { get; set; }

  @AuraEnabled
  public Decimal leadAcceptanceRate { get; set; }
  @AuraEnabled
  public Decimal leadConversionRate { get; set; }
  @AuraEnabled
  public Decimal dealWinRate { get; set; }

  @AuraEnabled
  public Decimal mdfAnnualBudget { get; set; }
  @AuraEnabled
  public Decimal mdfUsed { get; set; }
  @AuraEnabled
  public Decimal mdfRemaining { get; set; }
  @AuraEnabled
  public Decimal mdfUtilisationRate { get; set; }
}
