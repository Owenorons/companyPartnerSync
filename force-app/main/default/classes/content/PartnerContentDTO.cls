/*
 * Partner-facing content DTO returned by getAvailableContent(). Deliberately
 * excludes the visibility/targeting fields (visibility, partnerTier/Type,
 * isActive) present on PartnerContentAdminDTO — those are internal-only
 * filtering criteria, not data a partner should see.
 */
public with sharing class PartnerContentDTO {
  @AuraEnabled
  public Id contentId { get; set; }
  @AuraEnabled
  public String title { get; set; }
  @AuraEnabled
  public String description { get; set; }
  @AuraEnabled
  public String category { get; set; }
  @AuraEnabled
  public Boolean featured { get; set; }
  @AuraEnabled
  public Date publishedDate { get; set; }
}
