/**
 * Partner-facing content DTO returned by getAvailableContent(). Deliberately
 * excludes the visibility/targeting fields (visibility, partnerTier/Type,
 * isActive) present on PartnerContentAdminDTO — those are internal-only
 * filtering criteria, not data a partner should see.
 */
public with sharing class PartnerContentDTO {
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
   * Date the content was published.
   */
  @AuraEnabled
  public Date publishedDate { get; set; }
}
