/**
 * Inbound DTO for granting an activation-gate exception
 * (PartnerReadinessLifecycleController.grantException).
 */
public with sharing class PartnerExceptionGrantDTO {
  /**
   * Id of the Partner_Onboarding__c the exception applies to.
   */
  @AuraEnabled
  public Id onboardingId { get; set; }

  /**
   * The gate key to waive (documents, risk, approval, agreements,
   * relationship, access, training).
   */
  @AuraEnabled
  public String gate { get; set; }

  /**
   * Reason the exception is being granted.
   */
  @AuraEnabled
  public String reason { get; set; }

  /**
   * Date the exception starts applying.
   */
  @AuraEnabled
  public Date effectiveOn { get; set; }

  /**
   * Date the exception stops applying, if any.
   */
  @AuraEnabled
  public Date expiresOn { get; set; }
}
