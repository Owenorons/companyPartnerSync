/**
 * Row shape for the partner application review queue list view — summary
 * fields only, not the full application detail (see
 * PartnerApplicationDetailDTO for that).
 */
public with sharing class PartnerApplicationListDTO {
  /**
   * Id of the Partner_Application__c record.
   */
  @AuraEnabled
  public Id applicationId { get; set; }
  /**
   * Human-readable application number.
   */
  @AuraEnabled
  public String applicationNumber { get; set; }

  /**
   * Name of the applying company.
   */
  @AuraEnabled
  public String companyName { get; set; }

  /**
   * Partner tier requested on the application.
   */
  @AuraEnabled
  public String requestedTier { get; set; }
  /**
   * Type of partner being applied for (e.g. reseller, referral).
   */
  @AuraEnabled
  public String partnerType { get; set; }

  /**
   * Current review status of the application.
   */
  @AuraEnabled
  public String status { get; set; }
  /**
   * Date and time the application was submitted.
   */
  @AuraEnabled
  public Datetime submittedOn { get; set; }
}
