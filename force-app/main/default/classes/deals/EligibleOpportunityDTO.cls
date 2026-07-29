/*
 * Row shape for the "register a deal" opportunity picker — opportunities
 * belonging to the current partner that don't already have a deal
 * registration (see DealRegistrationSelector
 * .selectEligibleOpportunitiesForPartner).
 */
public with sharing class EligibleOpportunityDTO {
  @AuraEnabled
  public Id opportunityId;
  @AuraEnabled
  public String name;
  @AuraEnabled
  public String stageName;
  @AuraEnabled
  public Decimal amount;
  @AuraEnabled
  public Date closeDate;
}
