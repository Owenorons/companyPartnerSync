/*
 * Partner-facing content DTO returned by getAvailableContent(). Deliberately
 * excludes the visibility/targeting fields (visibility, partnerTier/Type,
 * isActive) present on PartnerContentAdminDTO — those are internal-only
 * filtering criteria, not data a partner should see.
 */
public with sharing class PartnerContentDTO {
  @AuraEnabled
  public Id contentId;
  @AuraEnabled
  public String title;
  @AuraEnabled
  public String description;
  @AuraEnabled
  public String category;
  @AuraEnabled
  public Boolean featured;
  @AuraEnabled
  public Date publishedDate;
}
