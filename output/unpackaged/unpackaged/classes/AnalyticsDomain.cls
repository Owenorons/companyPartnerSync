/**
 * Pure calculation layer for partner analytics: takes already-queried
 * SObjects/DTOs and derives KPI and leaderboard figures. Deliberately has
 * no SOQL, sharing, or permission logic so the math can be unit tested
 * without inserting records or running as a particular user.
 */
public with sharing class AnalyticsDomain {
  public static final Set<String> OPEN_PIPELINE_STATUSES = new Set<String>{
    'Submitted',
    'Needs Information',
    'Under Review',
    'Approved'
  };

  /** Shared inputs for partner KPI and leaderboard calculations. */
  public class KpiTotals {
    public Integer totalLeads = 0;
    public Integer acceptedLeads = 0;
    public Integer convertedLeads = 0;
    public Integer totalDeals = 0;
    public Integer approvedDeals = 0;
    public Integer wonDeals = 0;
    public Integer closedOpportunities = 0;
    public Decimal totalPipeline = 0;
    public Decimal totalRevenue = 0;
  }

  /**
   * Derives a partner's full KPI summary (lead, deal, revenue, and MDF
   * budget figures, plus health score/label/tier/signals) from
   * already-queried records.
   *
   * @param leads The partner's leads.
   * @param deals The partner's deal registrations.
   * @param opportunities The partner's opportunities.
   * @param budgetAccount The partner's Account record, with MDF budget fields populated.
   * @return The calculated KPI summary for the partner.
   */
  public static PartnerKPIDTO calculatePartnerKPI(
    List<Lead> leads,
    List<Deal_Registration__c> deals,
    List<Opportunity> opportunities,
    Account budgetAccount
  ) {
    KpiTotals totals = new KpiTotals();
    totals.totalLeads = leads.size();
    totals.totalDeals = deals.size();
    for (Lead lead : leads) {
      if (
        lead.Lead_Distribution_Status__c == 'Accepted' ||
        lead.Lead_Distribution_Status__c == 'Converted'
      ) {
        totals.acceptedLeads++;
      }
      if (lead.Lead_Distribution_Status__c == 'Converted') {
        totals.convertedLeads++;
      }
    }
    for (Deal_Registration__c deal : deals) {
      if (deal.Status__c == 'Approved') {
        totals.approvedDeals++;
      }
      if (OPEN_PIPELINE_STATUSES.contains(deal.Status__c)) {
        totals.totalPipeline += deal.Estimated_Revenue__c == null
          ? 0
          : deal.Estimated_Revenue__c;
      }
    }
    for (Opportunity opp : opportunities) {
      if (opp.IsClosed == true) {
        totals.closedOpportunities++;
      }
      if (opp.IsWon == true) {
        totals.wonDeals++;
        totals.totalRevenue += opp.Amount == null ? 0 : opp.Amount;
      }
    }
    return calculatePartnerKPI(totals, budgetAccount);
  }

  /**
   * Builds the same KPI contract from database aggregates or in-memory totals.
   * Acceptance includes converted leads; win rate uses closed opportunities.
   *
   * @param totals Counts and amounts for the partner.
   * @param budgetAccount The partner's budget fields.
   * @return Calculated KPIs and health signals.
   */
  public static PartnerKPIDTO calculatePartnerKPI(
    KpiTotals totals,
    Account budgetAccount
  ) {
    Decimal annualBudget = budgetAccount.MDF_Annual_Budget__c == null
      ? 0
      : budgetAccount.MDF_Annual_Budget__c;

    Decimal used = budgetAccount.MDF_Used__c == null
      ? 0
      : budgetAccount.MDF_Used__c;

    PartnerKPIDTO dto = new PartnerKPIDTO();

    dto.totalLeads = totals.totalLeads;
    dto.acceptedLeads = totals.acceptedLeads;
    dto.convertedLeads = totals.convertedLeads;

    dto.totalDeals = totals.totalDeals;
    dto.approvedDeals = totals.approvedDeals;
    dto.wonDeals = totals.wonDeals;

    dto.totalPipeline = totals.totalPipeline;
    dto.totalRevenue = totals.totalRevenue;

    dto.leadAcceptanceRate = totals.totalLeads == 0
      ? 0
      : Decimal.valueOf(totals.acceptedLeads) / totals.totalLeads;

    dto.leadConversionRate = totals.totalLeads == 0
      ? 0
      : Decimal.valueOf(totals.convertedLeads) / totals.totalLeads;

    dto.dealWinRate = totals.closedOpportunities == 0
      ? 0
      : Decimal.valueOf(totals.wonDeals) / totals.closedOpportunities;

    dto.mdfAnnualBudget = annualBudget;
    dto.mdfUsed = used;
    dto.mdfRemaining = annualBudget - used;
    dto.mdfUtilisationRate = annualBudget == 0 ? 0 : used / annualBudget;

    dto.healthScore = PartnerHealthScoringService.calculate(dto);
    dto.healthLabel = PartnerHealthScoringService.healthLabel(dto.healthScore);
    dto.recommendedTier = PartnerHealthScoringService.recommendTier(
      dto.healthScore
    );
    dto.healthSignals = PartnerHealthScoringService.explain(dto);

    return dto;
  }

  /**
   * Builds a single leaderboard row for a partner from its account details
   * and already-calculated KPI summary, reusing the KPI's health score if
   * present.
   *
   * @param partner The partner Account record.
   * @param kpi The partner's calculated KPI summary.
   * @return A leaderboard row for the partner.
   */
  public static PartnerLeaderboardRowDTO buildLeaderboardRow(
    Account partner,
    PartnerKPIDTO kpi
  ) {
    PartnerLeaderboardRowDTO dto = new PartnerLeaderboardRowDTO();

    dto.partnerAccountId = partner.Id;
    dto.partnerName = partner.Name;
    dto.partnerTier = partner.Partner_Tier__c;
    dto.partnerStatus = partner.Partner_Status__c;

    dto.acceptedLeads = kpi.acceptedLeads;
    dto.approvedDeals = kpi.approvedDeals;
    dto.wonDeals = kpi.wonDeals;

    dto.revenue = kpi.totalRevenue;
    dto.conversionRate = kpi.dealWinRate;

    // Use the same explainable 0-100 score shown to the partner so internal
    // rankings and partner-facing performance guidance cannot drift apart.
    dto.score = kpi.healthScore == null
      ? PartnerHealthScoringService.calculate(kpi)
      : kpi.healthScore;

    return dto;
  }
}
