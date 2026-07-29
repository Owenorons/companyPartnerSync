/*
 * Inbound DTO for a partner submitting a new deal registration from the
 * LWC. Consumed by DealRegistrationDomain.validate/buildRecord; distinct
 * from DealReviewDecisionDTO, which carries an internal reviewer's decision
 * on a deal that already exists.
 */
public with sharing class DealRegistrationRequestDTO {
  @AuraEnabled
  public Id opportunityId;
  @AuraEnabled
  public String businessProblem;
  @AuraEnabled
  public String proposedSolution;
  @AuraEnabled
  public Decimal estimatedRevenue;
  @AuraEnabled
  public Date estimatedCloseDate;
  @AuraEnabled
  public String implementationTimeline;
  @AuraEnabled
  public String notes;
}
