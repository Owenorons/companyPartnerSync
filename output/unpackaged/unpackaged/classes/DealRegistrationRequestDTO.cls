/**
 * Inbound DTO for a partner submitting a new deal registration from the
 * LWC. Consumed by DealRegistrationDomain.validate/buildRecord; distinct
 * from DealReviewDecisionDTO, which carries an internal reviewer's decision
 * on a deal that already exists.
 */
public with sharing class DealRegistrationRequestDTO {
  /**
   * Id of the opportunity being registered.
   */
  @AuraEnabled
  public Id opportunityId { get; set; }
  /**
   * Business problem the partner is proposing to solve.
   */
  @AuraEnabled
  public String businessProblem { get; set; }
  /**
   * Solution the partner is proposing.
   */
  @AuraEnabled
  public String proposedSolution { get; set; }
  /**
   * Estimated revenue value of the deal.
   */
  @AuraEnabled
  public Decimal estimatedRevenue { get; set; }
  /**
   * Estimated close date of the deal.
   */
  @AuraEnabled
  public Date estimatedCloseDate { get; set; }
  /**
   * Partner-provided implementation timeline for the deal.
   */
  @AuraEnabled
  public String implementationTimeline { get; set; }
  /**
   * Free-text notes provided by the partner.
   */
  @AuraEnabled
  public String notes { get; set; }
}
