public with sharing class Partner360DTO {
  @AuraEnabled
  public Id partnerAccountId { get; set; }
  @AuraEnabled
  public String partnerName { get; set; }
  @AuraEnabled
  public String partnerId { get; set; }
  @AuraEnabled
  public String partnerType { get; set; }
  @AuraEnabled
  public String tier { get; set; }
  @AuraEnabled
  public String region { get; set; }
  @AuraEnabled
  public String partnerStatus { get; set; }
  @AuraEnabled
  public Id onboardingId { get; set; }
  @AuraEnabled
  public String onboardingStatus { get; set; }
  @AuraEnabled
  public String currentStage { get; set; }
  @AuraEnabled
  public String activationGateStatus { get; set; }
  @AuraEnabled
  public Date recertificationDueOn { get; set; }
  @AuraEnabled
  public String relationshipStatus { get; set; }
  @AuraEnabled
  public String programmeKey { get; set; }
  @AuraEnabled
  public Integer openDocumentCount { get; set; }
  @AuraEnabled
  public Integer blockingFindingCount { get; set; }
  @AuraEnabled
  public Integer effectiveAgreementCount { get; set; }
  @AuraEnabled
  public Integer openAccessRequestCount { get; set; }
  @AuraEnabled
  public Integer incompleteTrainingCount { get; set; }
  @AuraEnabled
  public Integer openDealCount { get; set; }
  @AuraEnabled
  public Integer openMdfCount { get; set; }
  @AuraEnabled
  public List<String> blockers { get; set; }
  @AuraEnabled
  public List<Partner360EventDTO> recentEvents { get; set; }
}
