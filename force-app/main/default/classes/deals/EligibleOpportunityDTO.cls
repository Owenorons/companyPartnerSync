/*
 * Row shape for the "register a deal" opportunity picker — opportunities
 * belonging to the current partner that don't already have a deal
 * registration (see DealRegistrationSelector
 * .selectEligibleOpportunitiesForPartner).
 */
public with sharing class EligibleOpportunityDTO {
  @AuraEnabled
  public Id opportunityId { get; set; }
  @AuraEnabled
  public String name { get; set; }
  @AuraEnabled
  public String stageName { get; set; }
  @AuraEnabled
  public Decimal amount { get; set; }
  @AuraEnabled
  public Date closeDate { get; set; }
}
