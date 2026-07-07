public with sharing class AnalyticsDomain {
  public static PartnerKPIDTO calculatePartnerKPI(
    List<Lead> leads,
    List<Deal_Registration__c> deals,
    List<Opportunity> opportunities,
    Account budgetAccount
  ) {
    Integer acceptedLeads = 0;
    Integer convertedLeads = 0;

    for (Lead lead : leads) {
      if (lead.Lead_Distribution_Status__c == 'Accepted') {
        acceptedLeads++;
      }

      if (lead.Lead_Distribution_Status__c == 'Converted') {
        convertedLeads++;
      }
    }

    Integer approvedDeals = 0;
    Decimal totalPipeline = 0;

    for (Deal_Registration__c deal : deals) {
      if (deal.Status__c == 'Approved') {
        approvedDeals++;
      }

      totalPipeline += deal.Estimated_Revenue__c == null
        ? 0
        : deal.Estimated_Revenue__c;
    }

    Integer wonDeals = 0;
    Decimal totalRevenue = 0;

    for (Opportunity opp : opportunities) {
      if (opp.StageName == 'Closed Won') {
        wonDeals++;
        totalRevenue += opp.Amount == null ? 0 : opp.Amount;
      }
    }

    Decimal annualBudget = budgetAccount.MDF_Annual_Budget__c == null
      ? 0
      : budgetAccount.MDF_Annual_Budget__c;

    Decimal used = budgetAccount.MDF_Used__c == null
      ? 0
      : budgetAccount.MDF_Used__c;

    PartnerKPIDTO dto = new PartnerKPIDTO();

    dto.totalLeads = leads.size();
    dto.acceptedLeads = acceptedLeads;
    dto.convertedLeads = convertedLeads;

    dto.totalDeals = deals.size();
    dto.approvedDeals = approvedDeals;
    dto.wonDeals = wonDeals;

    dto.totalPipeline = totalPipeline;
    dto.totalRevenue = totalRevenue;

    dto.leadAcceptanceRate = leads.isEmpty()
      ? 0
      : Decimal.valueOf(acceptedLeads) / leads.size();

    dto.leadConversionRate = leads.isEmpty()
      ? 0
      : Decimal.valueOf(convertedLeads) / leads.size();

    dto.dealWinRate = deals.isEmpty()
      ? 0
      : Decimal.valueOf(wonDeals) / deals.size();

    dto.mdfAnnualBudget = annualBudget;
    dto.mdfUsed = used;
    dto.mdfRemaining = annualBudget - used;
    dto.mdfUtilisationRate = annualBudget == 0 ? 0 : used / annualBudget;

    return dto;
  }

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

    dto.score =
      (kpi.leadAcceptanceRate * 25) +
      (kpi.leadConversionRate * 25) +
      (kpi.dealWinRate * 30) +
      (kpi.mdfUtilisationRate * 20);

    return dto;
  }
}
