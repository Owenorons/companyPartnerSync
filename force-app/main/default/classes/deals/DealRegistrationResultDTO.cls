/**
 * Minimal confirmation returned to the partner right after a deal
 * registration is created (id/number/status/conflict status only) — the
 * partner does not get the full detail view; that richer shape
 * (DealReviewDetailDTO) is reserved for internal reviewers.
 */
public with sharing class DealRegistrationResultDTO {
  /**
   * Id of the newly created deal registration record.
   */
  @AuraEnabled
  public Id dealRegistrationId { get; set; }
  /**
   * Display name/number of the newly created deal registration record.
   */
  @AuraEnabled
  public String dealRegistrationNumber { get; set; }
  /**
   * Status of the newly created deal registration.
   */
  @AuraEnabled
  public String status { get; set; }
  /**
   * Conflict status of the newly created deal registration.
   */
  @AuraEnabled
  public String conflictStatus { get; set; }
}
