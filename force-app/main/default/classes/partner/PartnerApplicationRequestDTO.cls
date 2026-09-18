/**
 * Inbound submission payload for a brand-new partner application — the raw
 * form data before any record (Account/Contact/Partner_Application__c) has
 * been created for it.
 */
public with sharing class PartnerApplicationRequestDTO {
  /**
   * Name of the applying company.
   */
  @AuraEnabled
  public String companyName { get; set; }
  /**
   * Primary business email address for the applying company.
   */
  @AuraEnabled
  public String businessEmail { get; set; }
  /**
   * Contact phone number for the applying company.
   */
  @AuraEnabled
  public String phone { get; set; }
  /**
   * Website URL for the applying company.
   */
  @AuraEnabled
  public String website { get; set; }
  /**
   * Country the applying company is based in.
   */
  @AuraEnabled
  public String country { get; set; }
  /**
   * Region the applying company is based in.
   */
  @AuraEnabled
  public String region { get; set; }
  /**
   * Partner tier being requested.
   */
  @AuraEnabled
  public String requestedTier { get; set; }
  /**
   * Type of partner being applied for.
   */
  @AuraEnabled
  public String partnerType { get; set; }
  /**
   * Name of the contact submitting the application.
   */
  @AuraEnabled
  public String submittedByContactName { get; set; }
  /**
   * Email address of the contact submitting the application.
   */
  @AuraEnabled
  public String submittedByEmail { get; set; }
}
