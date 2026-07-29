/*
 * DTO for the internal (employee-facing) portal landing page. Carries
 * cross-object counts and alert strings the LWC layer renders as-is —
 * distinct from PartnerDashboardDTO, which reflects a single partner's
 * own data rather than org-wide review-queue counts.
 */
public with sharing class InternalDashboardDTO {
  @AuraEnabled
  public String userName;
  @AuraEnabled
  public Integer pendingDealReviewCount;
  @AuraEnabled
  public Integer pendingMdfReviewCount;
  @AuraEnabled
  public Integer unreadNotificationCount;
  @AuraEnabled
  public List<String> alerts;
}
