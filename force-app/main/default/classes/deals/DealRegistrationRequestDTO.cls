/*
 * Inbound DTO for a partner submitting a new deal registration from the
 * LWC. Consumed by DealRegistrationDomain.validate/buildRecord; distinct
 * from DealReviewDecisionDTO, which carries an internal reviewer's decision
 * on a deal that already exists.
 */
public with sharing class DealRegistrationRequestDTO {
  @AuraEnabled
  public Id opportunityId { get; set; }
  @AuraEnabled
  public String businessProblem { get; set; }
  @AuraEnabled
  public String proposedSolution { get; set; }
  @AuraEnabled
  public Decimal estimatedRevenue { get; set; }
  @AuraEnabled
  public Date estimatedCloseDate { get; set; }
  @AuraEnabled
  public String implementationTimeline { get; set; }
  @AuraEnabled
  public String notes { get; set; }
}
