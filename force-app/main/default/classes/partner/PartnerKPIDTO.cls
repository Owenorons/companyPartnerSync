public with sharing class PartnerKPIDTO {
  @AuraEnabled
  public Integer totalLeads;
  @AuraEnabled
  public Integer acceptedLeads;
  @AuraEnabled
  public Integer convertedLeads;

  @AuraEnabled
  public Integer totalDeals;
  @AuraEnabled
  public Integer approvedDeals;
  @AuraEnabled
  public Integer wonDeals;

  @AuraEnabled
  public Decimal totalPipeline;
  @AuraEnabled
  public Decimal totalRevenue;

  @AuraEnabled
  public Decimal leadAcceptanceRate;
  @AuraEnabled
  public Decimal leadConversionRate;
  @AuraEnabled
  public Decimal dealWinRate;

  @AuraEnabled
  public Decimal mdfAnnualBudget;
  @AuraEnabled
  public Decimal mdfUsed;
  @AuraEnabled
  public Decimal mdfRemaining;
  @AuraEnabled
  public Decimal mdfUtilisationRate;
}
