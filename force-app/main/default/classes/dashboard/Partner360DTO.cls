/**
 * DTO for the internal "Partner 360" single-partner detail view. Aggregates
 * a partner's onboarding, agreement, access, training, deal and MDF
 * standing into one payload for the LWC layer to render.
 */
public with sharing class Partner360DTO {
  /**
   * Id of the partner Account.
   */
  @AuraEnabled
  public Id partnerAccountId { get; set; }
  /**
   * Display name of the partner Account.
   */
  @AuraEnabled
  public String partnerName { get; set; }
  /**
   * External or business identifier for the partner.
   */
  @AuraEnabled
  public String partnerId { get; set; }
  /**
   * Type/category of the partner (e.g. reseller, referral).
   */
  @AuraEnabled
  public String partnerType { get; set; }
  /**
   * Partner's current tier.
   */
  @AuraEnabled
  public String tier { get; set; }
  /**
   * Partner's assigned region.
   */
  @AuraEnabled
  public String region { get; set; }
  /**
   * Partner's current relationship/account status.
   */
  @AuraEnabled
  public String partnerStatus { get; set; }
  /**
   * Id of the partner's onboarding record.
   */
  @AuraEnabled
  public Id onboardingId { get; set; }
  /**
   * Status of the partner's onboarding record.
   */
  @AuraEnabled
  public String onboardingStatus { get; set; }
  /**
   * Current onboarding stage the partner is in.
   */
  @AuraEnabled
  public String currentStage { get; set; }
  /**
   * Status of the partner's activation gate.
   */
  @AuraEnabled
  public String activationGateStatus { get; set; }
  /**
   * Date the partner's next recertification is due.
   */
  @AuraEnabled
  public Date recertificationDueOn { get; set; }
  /**
   * Status of the partner relationship.
   */
  @AuraEnabled
  public String relationshipStatus { get; set; }
  /**
   * Key of the partner programme the partner belongs to.
   */
  @AuraEnabled
  public String programmeKey { get; set; }
  /**
   * Count of documents currently open/outstanding for the partner.
   */
  @AuraEnabled
  public Integer openDocumentCount { get; set; }
  /**
   * Count of blocking compliance findings for the partner.
   */
  @AuraEnabled
  public Integer blockingFindingCount { get; set; }
  /**
   * Count of agreements currently in effect for the partner.
   */
  @AuraEnabled
  public Integer effectiveAgreementCount { get; set; }
  /**
   * Count of access requests currently open for the partner.
   */
  @AuraEnabled
  public Integer openAccessRequestCount { get; set; }
  /**
   * Count of required training items the partner has not completed.
   */
  @AuraEnabled
  public Integer incompleteTrainingCount { get; set; }
  /**
   * Count of deals currently open for the partner.
   */
  @AuraEnabled
  public Integer openDealCount { get; set; }
  /**
   * Count of MDF requests currently open for the partner.
   */
  @AuraEnabled
  public Integer openMdfCount { get; set; }
  /**
   * Human-readable blocker strings surfaced for the partner as-is.
   */
  @AuraEnabled
  public List<String> blockers { get; set; }
  /**
   * Most recent lifecycle events recorded for the partner.
   */
  @AuraEnabled
  public List<Partner360EventDTO> recentEvents { get; set; }
}
