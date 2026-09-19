/**
 * Row shape for the "register a deal" opportunity picker — opportunities
 * belonging to the current partner that don't already have a deal
 * registration (see DealRegistrationSelector
 * .selectEligibleOpportunitiesForPartner).
 */
public with sharing class EligibleOpportunityDTO {
  /**
   * Id of the eligible opportunity.
   */
  @AuraEnabled
  public Id opportunityId { get; set; }
  /**
   * Name of the eligible opportunity.
   */
  @AuraEnabled
  public String name { get; set; }
  /**
   * Stage name of the eligible opportunity.
   */
  @AuraEnabled
  public String stageName { get; set; }
  /**
   * Amount of the eligible opportunity.
   */
  @AuraEnabled
  public Decimal amount { get; set; }
  /**
   * Close date of the eligible opportunity.
   */
  @AuraEnabled
  public Date closeDate { get; set; }
}
