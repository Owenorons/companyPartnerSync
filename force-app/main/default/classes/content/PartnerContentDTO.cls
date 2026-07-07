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
