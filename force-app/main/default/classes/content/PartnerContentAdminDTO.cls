/*
 * DTO for the content-management admin UI. Superset of PartnerContentDTO —
 * carries visibility/targeting and lifecycle fields (isActive, visibility,
 * partnerTier/Type, sortOrder) that internal admins edit but partners never
 * see.
 */
public with sharing class PartnerContentAdminDTO {
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
  public Boolean isActive { get; set; }
  @AuraEnabled
  public String visibility { get; set; }
  @AuraEnabled
  public String partnerTier { get; set; }
  @AuraEnabled
  public String partnerType { get; set; }
  @AuraEnabled
  public Decimal sortOrder { get; set; }
}
