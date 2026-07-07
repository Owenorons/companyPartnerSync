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
