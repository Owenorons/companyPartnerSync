/*
 * DTO for the partner-portal landing page. Reflects the signed-in
 * partner's own deals/leads/MDF and account standing — distinct from
 * InternalDashboardDTO, which carries org-wide review-queue counts for
 * employees rather than one partner's own numbers.
 */
public with sharing class PartnerDashboardDTO {
  @AuraEnabled
  public String partnerName;
  @AuraEnabled
  public String partnerStatus;
  @AuraEnabled
  public String partnerTier;
  @AuraEnabled
  public Integer openDealCount;
  @AuraEnabled
  public Integer assignedLeadCount;
  @AuraEnabled
  public Integer openMdfCount;
  @AuraEnabled
  public List<String> alerts;
}
