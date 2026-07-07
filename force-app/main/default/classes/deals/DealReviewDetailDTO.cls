public with sharing class DealReviewDetailDTO {
  @AuraEnabled
  public Id dealId;
  @AuraEnabled
  public String dealNumber;

  @AuraEnabled
  public Id opportunityId;
  @AuraEnabled
  public Id customerAccountId;
  @AuraEnabled
  public Id partnerAccountId;

  @AuraEnabled
  public String customerName;
  @AuraEnabled
  public String partnerName;

  @AuraEnabled
  public Decimal estimatedRevenue;
  @AuraEnabled
  public Date estimatedCloseDate;

  @AuraEnabled
  public String businessProblem;
  @AuraEnabled
  public String proposedSolution;
  @AuraEnabled
  public String implementationTimeline;
  @AuraEnabled
  public String notes;

  @AuraEnabled
  public String status;
  @AuraEnabled
  public String conflictStatus;

  @AuraEnabled
  public Date protectionEndDate;
  @AuraEnabled
  public Datetime submittedOn;

  @AuraEnabled
  public List<DealConflictDetailDTO> conflicts;
}
