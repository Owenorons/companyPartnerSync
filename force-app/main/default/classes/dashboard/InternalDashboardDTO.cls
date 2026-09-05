/*
 * DTO for the internal (employee-facing) portal landing page. Carries
 * cross-object counts and alert strings the LWC layer renders as-is —
 * distinct from PartnerDashboardDTO, which reflects a single partner's
 * own data rather than org-wide review-queue counts.
 */
public with sharing class InternalDashboardDTO {
  @AuraEnabled
  public String userName { get; set; }
  @AuraEnabled
  public Integer pendingDealReviewCount { get; set; }
  @AuraEnabled
  public Integer pendingMdfReviewCount { get; set; }
  @AuraEnabled
  public Integer unreadNotificationCount { get; set; }
  @AuraEnabled
  public List<String> alerts { get; set; }
  @AuraEnabled
  public Integer blockedOnboardingCount { get; set; }
  @AuraEnabled
  public Integer onboardingWorkCount { get; set; }
  @AuraEnabled
  public Integer provisioningFailureCount { get; set; }
  @AuraEnabled
  public Integer recertificationDueCount { get; set; }
  @AuraEnabled
  public List<OnboardingWorkItemDTO> onboardingWorkItems { get; set; }
  @AuraEnabled
  public Integer totalOnboardingCount { get; set; }
  @AuraEnabled
  public Integer activeOnboardingCount { get; set; }
  @AuraEnabled
  public Decimal onboardingCompletionRate { get; set; }
  @AuraEnabled
  public Decimal averageActivationDays { get; set; }
  @AuraEnabled
  public Integer overdueOnboardingTaskCount { get; set; }
  @AuraEnabled
  public String onboardingBottleneckStage { get; set; }
  @AuraEnabled
  public Integer onboardingBottleneckCount { get; set; }
  @AuraEnabled
  public Integer expiredEvidenceCount { get; set; }
  @AuraEnabled
  public Integer expiringEvidenceCount { get; set; }
  @AuraEnabled
  public Integer overdueRequirementCount { get; set; }
  @AuraEnabled
  public List<PartnerComplianceItemDTO> complianceItems { get; set; }
  @AuraEnabled
  public Integer openOperationalAlertCount { get; set; }
  @AuraEnabled
  public List<OperationalAlertDTO> operationalAlerts { get; set; }
  @AuraEnabled
  public Integer unifiedWorkCount { get; set; }
  @AuraEnabled
  public List<UnifiedWorkItemDTO> unifiedWorkItems { get; set; }
}
