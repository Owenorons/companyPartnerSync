/**
 * DTO for the content-management admin UI. Superset of PartnerContentDTO —
 * carries visibility/targeting and lifecycle fields (isActive, visibility,
 * partnerTier/Type, sortOrder) that internal admins edit but partners never
 * see.
 */
public with sharing class PartnerContentAdminDTO {
  /**
   * Id of the underlying Partner_Content__c record.
   */
  @AuraEnabled
  public Id contentId { get; set; }
  /**
   * Content title.
   */
  @AuraEnabled
  public String title { get; set; }
  /**
   * Content description.
   */
  @AuraEnabled
  public String description { get; set; }
  /**
   * Content category.
   */
  @AuraEnabled
  public String category { get; set; }
  /**
   * Whether the content is flagged as featured.
   */
  @AuraEnabled
  public Boolean featured { get; set; }
  /**
   * Whether the content is active and eligible to be shown to partners.
   */
  @AuraEnabled
  public Boolean isActive { get; set; }
  /**
   * Visibility rule controlling which partners can see this content
   * (e.g. All Partners, Restricted, Internal Only).
   */
  @AuraEnabled
  public String visibility { get; set; }
  /**
   * Partner tier this content is restricted to, when visibility is
   * Restricted; blank matches any tier.
   */
  @AuraEnabled
  public String partnerTier { get; set; }
  /**
   * Partner type this content is restricted to, when visibility is
   * Restricted; blank matches any type.
   */
  @AuraEnabled
  public String partnerType { get; set; }
  /**
   * Sort order used to position this content within listings.
   */
  @AuraEnabled
  public Decimal sortOrder { get; set; }
}
