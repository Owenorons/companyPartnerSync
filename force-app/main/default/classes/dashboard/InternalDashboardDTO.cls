/**
 * DTO for the internal (employee-facing) portal landing page. Carries
 * cross-object counts and alert strings the LWC layer renders as-is —
 * distinct from PartnerDashboardDTO, which reflects a single partner's
 * own data rather than org-wide review-queue counts.
 */
public with sharing class InternalDashboardDTO {
  /**
   * Display name of the running internal user.
   */
  @AuraEnabled
  public String userName { get; set; }
  /**
   * Count of Deal Registrations currently awaiting internal review.
   */
  @AuraEnabled
  public Integer pendingDealReviewCount { get; set; }
  /**
   * Count of MDF requests currently awaiting internal review.
   */
  @AuraEnabled
  public Integer pendingMdfReviewCount { get; set; }
  /**
   * Count of unread notifications for the running internal user.
   */
  @AuraEnabled
  public Integer unreadNotificationCount { get; set; }
  /**
   * Human-readable alert strings surfaced on the internal dashboard as-is.
   */
  @AuraEnabled
  public List<String> alerts { get; set; }
  /**
   * Count of partner onboardings currently blocked.
   */
  @AuraEnabled
  public Integer blockedOnboardingCount { get; set; }
  /**
   * Count of onboarding work items requiring internal action.
   */
  @AuraEnabled
  public Integer onboardingWorkCount { get; set; }
  /**
   * Count of onboardings with a provisioning failure.
   */
  @AuraEnabled
  public Integer provisioningFailureCount { get; set; }
  /**
   * Count of partners with a recertification currently due.
   */
  @AuraEnabled
  public Integer recertificationDueCount { get; set; }
  /**
   * Onboarding work items shown in the internal review queue.
   */
  @AuraEnabled
  public List<OnboardingWorkItemDTO> onboardingWorkItems { get; set; }
  /**
   * Total count of partner onboardings across all statuses.
   */
  @AuraEnabled
  public Integer totalOnboardingCount { get; set; }
  /**
   * Count of partner onboardings currently in progress.
   */
  @AuraEnabled
  public Integer activeOnboardingCount { get; set; }
  /**
   * Portfolio-wide onboarding completion rate.
   */
  @AuraEnabled
  public Decimal onboardingCompletionRate { get; set; }
  /**
   * Average number of days from onboarding start to activation.
   */
  @AuraEnabled
  public Decimal averageActivationDays { get; set; }
  /**
   * Count of onboarding tasks that are past their due date.
   */
  @AuraEnabled
  public Integer overdueOnboardingTaskCount { get; set; }
  /**
   * Name of the onboarding stage where the most partners are stuck.
   */
  @AuraEnabled
  public String onboardingBottleneckStage { get; set; }
  /**
   * Count of partners stuck at the bottleneck onboarding stage.
   */
  @AuraEnabled
  public Integer onboardingBottleneckCount { get; set; }
  /**
   * Count of compliance evidence records that have expired.
   */
  @AuraEnabled
  public Integer expiredEvidenceCount { get; set; }
  /**
   * Count of compliance evidence records expiring soon.
   */
  @AuraEnabled
  public Integer expiringEvidenceCount { get; set; }
  /**
   * Count of compliance requirements that are overdue.
   */
  @AuraEnabled
  public Integer overdueRequirementCount { get; set; }
  /**
   * Portfolio-level compliance issues shown to internal operators.
   */
  @AuraEnabled
  public List<PartnerComplianceItemDTO> complianceItems { get; set; }
  /**
   * Count of operational alerts currently open.
   */
  @AuraEnabled
  public Integer openOperationalAlertCount { get; set; }
  /**
   * Operational alerts shown on the internal dashboard.
   */
  @AuraEnabled
  public List<OperationalAlertDTO> operationalAlerts { get; set; }
  /**
   * Count of items in the unified cross-domain work queue.
   */
  @AuraEnabled
  public Integer unifiedWorkCount { get; set; }
  /**
   * Items in the unified cross-domain work queue shown to internal operators.
   */
  @AuraEnabled
  public List<UnifiedWorkItemDTO> unifiedWorkItems { get; set; }
}
