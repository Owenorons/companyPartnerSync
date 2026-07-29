/*
 * DTO for the content-management admin UI. Superset of PartnerContentDTO —
 * carries visibility/targeting and lifecycle fields (isActive, visibility,
 * partnerTier/Type, sortOrder) that internal admins edit but partners never
 * see.
 */
public with sharing class PartnerContentAdminDTO {
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
  public Boolean isActive;
  @AuraEnabled
  public String visibility;
  @AuraEnabled
  public String partnerTier;
  @AuraEnabled
  public String partnerType;
  @AuraEnabled
  public Decimal sortOrder;
}
