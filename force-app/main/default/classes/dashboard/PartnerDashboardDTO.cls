/*
 * DTO for the partner-portal landing page. Reflects the signed-in
 * partner's own deals/leads/MDF and account standing — distinct from
 * InternalDashboardDTO, which carries org-wide review-queue counts for
 * employees rather than one partner's own numbers.
 */
public with sharing class PartnerDashboardDTO {
  @AuraEnabled
  public String partnerName { get; set; }
  @AuraEnabled
  public String partnerStatus { get; set; }
  @AuraEnabled
  public String partnerTier { get; set; }
  @AuraEnabled
  public Integer openDealCount { get; set; }
  @AuraEnabled
  public Integer assignedLeadCount { get; set; }
  @AuraEnabled
  public Integer openMdfCount { get; set; }
  @AuraEnabled
  public List<String> alerts { get; set; }
}
