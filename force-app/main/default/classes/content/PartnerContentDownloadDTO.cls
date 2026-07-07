public with sharing class PartnerContentDownloadDTO {
  @AuraEnabled
  public Id contentId;
  @AuraEnabled
  public String downloadUrl;
}
