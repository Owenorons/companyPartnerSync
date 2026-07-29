/*
 * Minimal confirmation returned to the partner right after a deal
 * registration is created (id/number/status/conflict status only) — the
 * partner does not get the full detail view; that richer shape
 * (DealReviewDetailDTO) is reserved for internal reviewers.
 */
public with sharing class DealRegistrationResultDTO {
  @AuraEnabled
  public Id dealRegistrationId;
  @AuraEnabled
  public String dealRegistrationNumber;
  @AuraEnabled
  public String status;
  @AuraEnabled
  public String conflictStatus;
}
