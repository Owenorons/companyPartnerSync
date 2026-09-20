/** Portfolio-level evidence issue shown to authorised internal operators. */
public with sharing class PartnerComplianceItemDTO {
  /**
   * Id of the underlying compliance/evidence record.
   */
  @AuraEnabled
  public Id recordId { get; set; }
  /**
   * Id of the onboarding record this compliance item belongs to.
   */
  @AuraEnabled
  public Id onboardingId { get; set; }
  /**
   * Category of the compliance item.
   */
  @AuraEnabled
  public String category { get; set; }
  /**
   * Type of document the compliance item relates to.
   */
  @AuraEnabled
  public String documentType { get; set; }
  /**
   * Current status of the compliance item.
   */
  @AuraEnabled
  public String status { get; set; }
  /**
   * Severity of the compliance issue.
   */
  @AuraEnabled
  public String severity { get; set; }
  /**
   * Date the compliance item is due.
   */
  @AuraEnabled
  public Date dueOn { get; set; }
  /**
   * Human-readable message describing the compliance issue.
   */
  @AuraEnabled
  public String message { get; set; }
}
