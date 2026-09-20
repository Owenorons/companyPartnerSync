/**
 * DTO for the partner-portal landing page. Reflects the signed-in
 * partner's own deals/leads/MDF and account standing — distinct from
 * InternalDashboardDTO, which carries org-wide review-queue counts for
 * employees rather than one partner's own numbers.
 */
public with sharing class PartnerDashboardDTO {
  /**
   * Display name of the signed-in partner Account.
   */
  @AuraEnabled
  public String partnerName { get; set; }
  /**
   * Current status of the partner Account.
   */
  @AuraEnabled
  public String partnerStatus { get; set; }
  /**
   * Current tier of the partner Account.
   */
  @AuraEnabled
  public String partnerTier { get; set; }
  /**
   * Count of deals currently open for the partner.
   */
  @AuraEnabled
  public Integer openDealCount { get; set; }
  /**
   * Count of leads currently assigned to the partner.
   */
  @AuraEnabled
  public Integer assignedLeadCount { get; set; }
  /**
   * Count of MDF requests currently open for the partner.
   */
  @AuraEnabled
  public Integer openMdfCount { get; set; }
  /**
   * Human-readable alert strings surfaced on the partner dashboard as-is.
   */
  @AuraEnabled
  public List<String> alerts { get; set; }
}
